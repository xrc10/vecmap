# Evaluate on MUSE dataset

NAME=save/MUSE/;
EVAL_ROOT=../EvaluateCLEMb/;
DATA_ROOT=../data/MUSE/;
MAX_VOCAB=200000;
EMB_DIM=300;
TGT_LANG=en;
VAL_SPLIT=5000-6500;
# VAL_SPLIT=0-5000;

# SRC_LANGS=( fr )
# SRC_LANGS=( fr es de ru zh eo bg ca da fi ja ko sk sl ta tr uk vi tl th sv sq ro pt no nl ms lv ko hu id hr hi he fa et el cs bs bn ar af )
SRC_LANGS=( af ar bg bn bs ca cs da de el es et fa fi fr he hi hr hu id it ja ko lt lv mk ms nl no pl pt ro ru sk sl sq sv ta th tl tr uk vi zh )

# Methods and command
METHODS=(   "Mikolov:--whiten --src_reweight --src_dewhiten trg --trg_dewhiten trg"
            "Zhang:"
            "Xing:--normalize unit"
            "Shigeto:--whiten --trg_reweight --src_dewhiten src --trg_dewhiten src" 
            "Artetxe16:--normalize unit center"
            "Artetxe17:--normalize unit center --orthogonal --numerals --self_learning -v")

# for ((i=0;i<${#SRC_LANGS[@]};i+=1));
# do
#     SRC_LANG=${SRC_LANGS[$i]};
#     # export CUDA_VISIBLE_DEVICES=3;
#     for method_command in "${METHODS[@]}"
#     do
#         METHOD="${method_command%%:*}";
#         echo "Evaluaing $SRC_LANG  $METHOD";
#         python "$EVAL_ROOT"/evaluate_MUSE.py --exp_path "$NAME"/"$SRC_LANG"-en/"$METHOD"/ --src_lang en --tgt_lang "$SRC_LANG" --src_emb "$NAME"/"$SRC_LANG"-en/"$METHOD"/wiki.en.mapped.vec --tgt_emb "$NAME"/"$SRC_LANG"-en/"$METHOD"/wiki."$SRC_LANG".mapped.vec --max_vocab $MAX_VOCAB --emb_dim $EMB_DIM --eval_path "$DATA_ROOT" --cuda False;
#         python "$EVAL_ROOT"/evaluate_MUSE.py --exp_path "$NAME"/"$SRC_LANG"-en/"$METHOD"/ --src_lang "$SRC_LANG" --tgt_lang en --src_emb "$NAME"/"$SRC_LANG"-en/"$METHOD"/wiki."$SRC_LANG".mapped.vec --tgt_emb "$NAME"/"$SRC_LANG"-en/"$METHOD"/wiki.en.mapped.vec --max_vocab $MAX_VOCAB --emb_dim $EMB_DIM --eval_path "$DATA_ROOT" --cuda False;
#         # exit 1
#     done
# done

# Print the table
for method_command in "${METHODS[@]}"
do
    METHOD="${method_command%%:*}";
    echo "----------------------" > my_scripts/MUSE_"$METHOD".log
    IFS=$'\n' SORTED_SRC_LANGS=($(sort <<<"${SRC_LANGS[*]}"))

    for ((i=0;i<${#SORTED_SRC_LANGS[@]};i+=1));
    do
        SRC_LANG=${SORTED_SRC_LANGS[$i]};
        echo -ne "$SRC_LANG"-en"\t"en-"$SRC_LANG""\t" >> my_scripts/MUSE_"$METHOD".log
    done

    echo "----------------------" >> my_scripts/MUSE_"$METHOD".log

    for p in 1 5 10
    do
        for ((i=0;i<${#SORTED_SRC_LANGS[@]};i+=1));
        do
            SRC_LANG=${SORTED_SRC_LANGS[$i]};
            acc1=$(cat "$NAME"/"$SRC_LANG"-en/"$METHOD"/"$SRC_LANG"-"$TGT_LANG"-"$VAL_SPLIT"_word_trans_p@"$p");
            acc2=$(cat "$NAME"/"$SRC_LANG"-en/"$METHOD"/"$TGT_LANG"-"$SRC_LANG"-"$VAL_SPLIT"_word_trans_p@"$p") 
            echo -ne "$acc1""\t""$acc2""\t" >> my_scripts/MUSE_"$METHOD".log
        done
        echo "----------------------" >> my_scripts/MUSE_"$METHOD".log
    done

    for ((i=0;i<${#SORTED_SRC_LANGS[@]};i+=1));
    do
        SRC_LANG=${SORTED_SRC_LANGS[$i]};
        SRC_LANG_UP=$(echo "$SRC_LANG" | tr /a-z/ /A-Z/);
        # echo $SRC_LANG_UP
        corr1=$(cat "$NAME"/"$SRC_LANG"-en/"$METHOD"/"$SRC_LANG"-en-"$SRC_LANG_UP"_EN_SEMEVAL17);
        corr2=$(cat "$NAME"/"$SRC_LANG"-en/"$METHOD"/"$SRC_LANG"-en-EN_"$SRC_LANG_UP"_SEMEVAL17);
        echo -ne "$corr1""\t""$corr2""\t" >> my_scripts/MUSE_"$METHOD".log;
    done
    echo "----------------------" >> my_scripts/MUSE_"$METHOD".log

done