#!/bin/bash

lockfile_sdm="/tmp/run_sdm.lock"
if [ -f "$lockfile_sdm" ]; then
    echo "Another instance of the script is running"
    exit 1
fi

lockfile_neus2="/tmp/run_skoltech3d_neus2.lock"
if [ -f "$lockfile_neus2" ]; then
    echo "NeuS2 is running"
    exit 1
fi

lockfile_rnb="/tmp/run_skoltech3d.lock"
if [ -f "$lockfile_rnb" ]; then
    echo "RNb is running"
    exit 1
fi

touch $lockfile_neus2
trap "rm -f $lockfile_neus2" EXIT

data_dir="/home/bbrument/dev/EVAL_DLMV_DTU/EVAL/skoltech3d/data/unimsps"
results_dir="/home/bbrument/dev/EVAL_DLMV_DTU/EVAL/skoltech3d/results/neus2"

exps=1
n_views="10 5"
datasets="dragon golden_snail plush_bear jin_chan green_carved_pot moon_pillow painted_cup red_ceramic_fish painted_samovar green_tea_boxes blue_boxing_gloves golden_bust small_wooden_chessboard amber_vase green_bucket white_human_skull orange_mini_vacuum pink_boot skate white_castle_land wooden_trex"
for exp in $(seq 1 $exps)
do
    for dataset in $datasets
    do

        if [ ! -f "$data_dir/$dataset/normal/0099.png" ] && [ ! -f "$data_dir/$dataset/mask/0099.png" ]; then
            echo "Dataset $dataset does not exist"
            continue
        fi

        for n_view in $n_views
        do 

            if [ $n_view == "100" ]; then
                data_dir_view=$data_dir
            else
                data_dir_view="$data_dir-$n_view"
                
                if [ $n_view == "50" ]; then
                    /mnt/sdc1/bbrument/anaconda3/envs/rnbneus2/bin/python select_ind_idr.py --data_path $data_dir/$dataset --output_path $data_dir_view/$dataset --ind_images 0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 98
                elif [ $n_view == "20" ]; then
                    /mnt/sdc1/bbrument/anaconda3/envs/rnbneus2/bin/python select_ind_idr.py --data_path $data_dir/$dataset --output_path $data_dir_view/$dataset --ind_images 0 5 10 16 21 26 32 37 42 47 53 58 63 68 74 79 84 89 95 99
                elif [ $n_view == "10" ]; then
                    /mnt/sdc1/bbrument/anaconda3/envs/rnbneus2/bin/python select_ind_idr.py --data_path $data_dir/$dataset --output_path $data_dir_view/$dataset --ind_images 0 11 22 33 44 55 66 77 88 99
                elif [ $n_view == "5" ]; then
                    /mnt/sdc1/bbrument/anaconda3/envs/rnbneus2/bin/python select_ind_idr.py --data_path $data_dir/$dataset --output_path $data_dir_view/$dataset --ind_images 0 25 50 75 99
                elif [ $n_view == "2" ]; then
                    /mnt/sdc1/bbrument/anaconda3/envs/rnbneus2/bin/python select_ind_idr.py --data_path $data_dir/$dataset --output_path $data_dir_view/$dataset --ind_images 0 99
                fi
            fi

            output_path="$results_dir/$dataset/n_views-$n_view/exp$exp"
            if [ -f "$output_path/mesh_50000_.obj" ]; then
                continue
            fi

            if [ ! -f "$data_dir_view/$dataset/neus_data/transforms.json" ]; then
                /mnt/sdc1/bbrument/anaconda3/envs/rnbneus2/bin/python /home/bbrument/dev/convertSfmDataFormat/idr2nerf.py --idr_folder_path $data_dir_view/$dataset --output_format neus2 --output_path $data_dir_view/$dataset/neus_data --use-scale-matrix --bit_depth 8 --copy_images
            fi

            output_path="$results_dir/$dataset/n_views-$n_view/exp$exp"
            if [ ! -f "$output_path/mesh_50000_.obj" ]; then
                ./build/testbed --scene $data_dir_view/$dataset/neus_data --maxiter 50000 --save-mesh --save-snapshot --no-gui --resolution 768
                
                mkdir -p $output_path
                mv $data_dir_view/$dataset/mesh_*_.obj $output_path
                rm -rf $data_dir_view/$dataset/snapshot_50000.msgpack
            fi

            if [ -f "$data_dir_view/$dataset/neus_data/transforms.json" ]; then
                rm -rf "$data_dir_view/$dataset/neus_data"
            fi

            # exit 0

        done
    done
done
