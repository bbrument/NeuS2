#!/bin/bash

lockfile="/tmp/lockfile_run_lucesmv"
if [ -f "$lockfile" ]; then
    echo "Already running"
    exit
fi

lockfile="/tmp/lockfile_run_dlmv_uni_gt_cnn"
if [ -f "$lockfile" ]; then
    echo "Already running"
    exit
fi

# Add NeuS2 lockfile check
lockfile="/tmp/lockfile_run_skoltech_neus2"
if [ -f "$lockfile" ]; then
    echo "NeuS2 is already running"
    exit
fi

touch $lockfile
trap "rm -f $lockfile" EXIT

CONVERT_DIR="/home/bbrument/dev/convertSfmDataFormat"
NEUS2_PATH="/home/bbrument/dev/NeuS2"

PYTHON_PATH="/home/bbrument/anaconda3/envs/py_eval/bin"

# Settings
BASE_DATA_DIR="/home/bbrument/dev/NeuS2/data"
dataset_name="skoltech3d"
datasets="wooden_trex white_castle_land skate pink_boot orange_mini_vacuum white_human_skull green_bucket amber_vase small_wooden_chessboard golden_bust blue_boxing_gloves green_tea_boxes painted_samovar red_ceramic_fish painted_cup moon_pillow green_carved_pot jin_chan plush_bear golden_snail dragon"

methods="neus2"
exps=1
n_views="20" # 10 5"
# option_loss="norm2 norm1"
n_iters="50000"
res="768"

for dataset in $datasets
do
    
    data_dir="$BASE_DATA_DIR/$dataset_name/data/mvs/$dataset"
    if [ ! -f "$data_dir/image/0099.png" ] || [ ! -f "$data_dir/mask/0099.png" ]; then
        echo "Dataset $dataset does not exist in MVS directory"
        continue
    fi

    for n_view in $n_views
    do
        if [ $n_view == "100" ]; then
            data_dir_view=$data_dir
        else
            data_dir_view="$BASE_DATA_DIR/$dataset_name/data/mvs-${n_view}/$dataset"
            
            if [ ! -d "$data_dir_view" ]; then

                if [ $n_view == "50" ]; then
                    $PYTHON_PATH/python $NEUS2_PATH/select_ind_idr.py --data_path $data_dir --output_path $data_dir_view --ind_images 0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 98
                elif [ $n_view == "20" ]; then
                    $PYTHON_PATH/python $NEUS2_PATH/select_ind_idr.py --data_path $data_dir --output_path $data_dir_view --ind_images 1 5 10 16 21 35 39 42 47 51 58 62 69 75 80 88 92 94 97 99
                elif [ $n_view == "10" ]; then
                    $PYTHON_PATH/python $NEUS2_PATH/select_ind_idr.py --data_path $data_dir --output_path $data_dir_view --ind_images 1 13 19 32 46 58 64 71 83 94
                elif [ $n_view == "5" ]; then
                    $PYTHON_PATH/python $NEUS2_PATH/select_ind_idr.py --data_path $data_dir --output_path $data_dir_view --ind_images 14 25 29 78 88
                elif [ $n_view == "2" ]; then
                    $PYTHON_PATH/python $NEUS2_PATH/select_ind_idr.py --data_path $data_dir --output_path $data_dir_view --ind_images 51 56
                fi
            fi
        fi

        for method in $methods
        do

            eval_dir="$BASE_DATA_DIR/$dataset_name/eval/$dataset/$method"

            for exp in $(seq 1 $exps)
            do

                output_dir="$eval_dir/nbv-$n_view/nbit-${n_iters}/exp$exp"
                output_path2="$output_dir/results_raw/${dataset}_${method}_nbv-${n_view}_nbit-${n_iters}_exp${exp}.obj"
                output_path3="$output_dir/results_cleaned/${dataset}_${method}_nbv-${n_view}_nbit-${n_iters}_exp${exp}_cleaned.ply"
                if [ ! -f "$output_path2" ] && [ ! -f "$output_path3" ]; then
                                
                    lockfile_run="$output_dir/lockfile_run"
                    if [ -f "$lockfile_run" ]; then
                        echo "Already running $dataset with $n_view views"
                        continue
                    fi
                    mkdir -p $output_dir/results_raw
                    # touch $lockfile_run

                    if [ ! -f "$data_dir_view/neus_data/transforms.json" ]; then
                        echo "Preprocessing $dataset with $n_view views for NeuS2"
                        echo "$PYTHON_PATH/python $CONVERT_DIR/idr2nerf.py --idr_folder_path $data_dir_view --output_format neus2 --output_path $data_dir_view/neus_data --use-scale-matrix --bit_depth 8 --copy_images"
                        $PYTHON_PATH/python $CONVERT_DIR/idr2nerf.py --idr_folder_path $data_dir_view --output_format neus2 --output_path $data_dir_view/neus_data --use-scale-matrix --bit_depth 8 --copy_images
                    fi

                    echo "Running $dataset with $n_view views for NeuS2"
                    echo "$NEUS2_PATH/build/testbed --scene $data_dir_view/neus_data --maxiter $n_iters --save-mesh --save-snapshot --no-gui --resolution $res"
                    $NEUS2_PATH/build/testbed --scene $data_dir_view/neus_data --maxiter $n_iters \
                        --save-mesh --save-snapshot --resolution $res # --no-gui

                    mv $data_dir_view/neus_data/../mesh_* $output_path2
                    rm $data_dir_view/neus_data/../snapshot_*.msgpack
                    rm -f $lockfile_run
                fi
            done
        done

        if [ -f "$data_dir_view/neus_data/transforms.json" ]; then
            echo "Cleaning up $dataset with $n_view views"
            rm -rf "$data_dir_view/neus_data"
        fi
    done
done