# Run MUSE dataset

DATA_ROOT=../data/UBiLexAT/;
# PRE_DATA_ROOT=data/MUSE_PRE/;
EVAL_ROOT=../EvaluateCLEMb/;
NAME=save/UBiLexAT/

TRAIN_MAX_SIZE=200000

PHASE=2 # 0-preprocessing # 1-sup train mapping # 2-(nearly) unsup train mapping # 3-evaluate sup train # 4-evaluate unsup train

TGT_LANG=en
SRC_LANGS=(tr es zh it)

# Methods and command
METHODS=(   "Artetxe16:--normalize unit center"
            "Zhang:"
            "Xing:--normalize unit"
            "Shigeto:--whiten --trg_reweight --src_dewhiten src --trg_dewhiten src" 
            "Mikolov:--whiten --src_reweight --src_dewhiten trg --trg_dewhiten trg")

for i in 0 1 2 3
do
    SRC_LANG=${SRC_LANGS[$i]};
    echo $SRC_LANG;
    DATA_PATH="$DATA_ROOT"/"$SRC_LANG"-"$TGT_LANG"
    # Embedding Paths
    TGT_EMB_PATH=$DATA_ROOT/"$SRC_LANG"-"$TGT_LANG"/word2vec."$TGT_LANG"
    SRC_EMB_PATH=$DATA_ROOT/"$SRC_LANG"-"$TGT_LANG"/word2vec."$SRC_LANG"

    SAVE_PATH=$NAME/$SRC_LANG-$TGT_LANG/;

    # Dictionary paths
    VAL_DICT_PATH="$DATA_ROOT"/"$SRC_LANG"-"$TGT_LANG"/"$SRC_LANG"-"$TGT_LANG".dict.tst.txt
    TRN_DICT_PATH="$DATA_ROOT"/"$SRC_LANG"-"$TGT_LANG"/"$SRC_LANG"-"$TGT_LANG".dict.trn.txt

    if [ "$PHASE" = 1 ]; then # train the mapping with full dictionary
        echo "training the mapping with full labels ... "
        for method_command in "${METHODS[@]}"
        do
            METHOD="${method_command%%:*}";
            COMMAND="${method_command##*:}";
            # echo "$METHOD" "$COMMAND"
            mkdir -p $SAVE_PATH/$METHOD
            MAPPED_TGT_EMB_PATH=$SAVE_PATH/$METHOD/wiki.$TGT_LANG.mapped.vec
            MAPPED_SRC_EMB_PATH=$SAVE_PATH/$METHOD/wiki.$SRC_LANG.mapped.vec
            python3 map_embeddings.py $SRC_EMB_PATH $TGT_EMB_PATH $MAPPED_SRC_EMB_PATH $MAPPED_TGT_EMB_PATH $COMMAND -d $TRN_DICT_PATH --validation $VAL_DICT_PATH --log $SAVE_PATH/$METHOD/logger.txt;
            # echo "$METHOD" "$COMMAND"
            # exit -1 
        done

    elif [ "$PHASE" = 2 ]; then #
        echo "training the mapping with partial labels ... "
        mkdir -p $SAVE_PATH/Artetxe17;
        MAPPED_TGT_EMB_PATH=$SAVE_PATH/Artetxe17/wiki.$TGT_LANG.mapped.vec
        MAPPED_SRC_EMB_PATH=$SAVE_PATH/Artetxe17/wiki.$SRC_LANG.mapped.vec
        python3 map_embeddings.py --orthogonal --normalize unit center $SRC_EMB_PATH $TGT_EMB_PATH $MAPPED_SRC_EMB_PATH $MAPPED_TGT_EMB_PATH --numerals --self_learning -v --validation $VAL_DICT_PATH --log $SAVE_PATH/Artetxe17/logger.txt

    elif [ "$PHASE" = 3 ]; then #
        echo "evaluating ... "
        # for method_command in "${METHODS[@]}"
        # do
        #     METHOD="${method_command%%:*}";
        #     COMMAND="${method_command##*:}";
        #     MAPPED_TGT_EMB_PATH=$SAVE_PATH/$METHOD/wiki.$TGT_LANG.mapped.vec
        #     MAPPED_SRC_EMB_PATH=$SAVE_PATH/$METHOD/wiki.$SRC_LANG.mapped.vec
        #     python $EVAL_ROOT/eval_knn_acc.py -src_emb_path $MAPPED_SRC_EMB_PATH -tgt_emb_path $MAPPED_TGT_EMB_PATH -dictionary $VAL_DICT_PATH > $SAVE_PATH/$METHOD/eval_knn_acc.$SRC_LANG-$TGT_LANG.log 2> $SAVE_PATH/$METHOD/"$SRC_LANG"-"$TGT_LANG".acc
        #     python $EVAL_ROOT/eval_knn_acc.py -src_emb_path $MAPPED_SRC_EMB_PATH -tgt_emb_path $MAPPED_TGT_EMB_PATH -dictionary $VAL_DICT_PATH -src2tgt 0 > $SAVE_PATH/$METHOD/eval_knn_acc.$TGT_LANG-$SRC_LANG.log 2> $SAVE_PATH/$METHOD/"$TGT_LANG"-"$SRC_LANG".acc
        # done
    fi
done

if [ $PHASE = 3 ]; then
    echo "----------------------" > my_scripts/UBiLexAT.log
    echo -ne "Method\t" >> my_scripts/UBiLexAT.log
    for i in 0 1 2 3
    do
        SRC_LANG=${SRC_LANGS[$i]};
        echo -ne "$SRC_LANG"-en"\t"en-"$SRC_LANG""\t" >> my_scripts/UBiLexAT.log
    done
    echo "" >> my_scripts/UBiLexAT.log
    echo "----------------------" >> my_scripts/UBiLexAT.log
    for method_command in "${METHODS[@]}"
    do
        METHOD="${method_command%%:*}";
        echo -ne "$METHOD""\t" >> my_scripts/UBiLexAT.log
        for i in 0 1 2 3
        do
            SRC_LANG=${SRC_LANGS[$i]};
            SAVE_PATH=$NAME/$SRC_LANG-$TGT_LANG/;
            acc1=$(cat "$SAVE_PATH/$METHOD"/"$SRC_LANG"-"$TGT_LANG".acc) 
            acc2=$(cat "$SAVE_PATH/$METHOD"/"$TGT_LANG"-"$SRC_LANG".acc) 
            echo -ne "$acc1""\t""$acc2""\t" >> my_scripts/UBiLexAT.log
        done
        echo "" >> my_scripts/UBiLexAT.log
    done
fi