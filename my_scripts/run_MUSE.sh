# Run MUSE dataset

DATA_ROOT=../data/MUSE/;
PRE_DATA_ROOT=data/MUSE_PRE/;
EVAL_ROOT=../EvaluateCLEMb/;

TGT_LANG=en
SEED_SIZE=200
TRN_SPLIT=0-5000
VAL_SPLIT=5000-6500
TRAIN_MAX_SIZE=200000
UNSUP_TRAIN_MAX_SIZE=10000 # for unsupervised training, 200000 is too large in terms of running time

PHASE=1 # 0-preprocessing # 1-sup train mapping # 2-(nearly) unsup train mapping # 3-evaluate

# SRC_LANGS=( fr es de ru zh eo bg ca da fi ja ko sk sl ta tr uk vi tl th sv sq ro pt no nl ms lv ko hu id hr hi he fa et el cs bs bn ar af )
# SRC_LANGS=( af ar bg bn bs ca cs da de el en es et fa fi fr he hi hr hu id it ja ko lt lv mk ms nl no pl pt ro ru sk sl sq sv ta th tl tr uk vi zh )
# SRC_LANGS=( it mk lt pl )
SRC_LANGS=( af ar bg bn bs ca cs da de el es et fa fi fr he hi hr hu id it ja ko lt lv mk ms nl no pl pt ro ru sk sl sq sv ta th tl tr uk vi zh )

# Methods and command
METHODS=(   "Mikolov:--whiten --src_reweight --src_dewhiten trg --trg_dewhiten trg"
            "Zhang:"
            "Xing:--normalize unit"
            "Shigeto:--whiten --trg_reweight --src_dewhiten src --trg_dewhiten src" 
            "Artetxe16:--normalize unit center")

            # "Artetxe17:--normalize unit center --orthogonal --numerals --self_learning -v")

for ((i=0;i<${#SRC_LANGS[@]};i+=1));
do
    SRC_LANG=${SRC_LANGS[$i]};
    echo $SRC_LANG;
    # Embedding Paths
    TGT_EMB_PATH=$DATA_ROOT/wiki.$TGT_LANG.vec
    # NORM_TGT_EMB_PATH=$PRE_DATA_ROOT/wiki.$TGT_LANG.norm.vec
    SRC_EMB_PATH=$DATA_ROOT/wiki.$SRC_LANG.vec
    # NORM_SRC_EMB_PATH=$PRE_DATA_ROOT/wiki.$SRC_LANG.norm.vec

    SAVE_PATH=save/MUSE/$SRC_LANG-$TGT_LANG/;

    # Dictionary paths
    VAL_DICT_PATH="$DATA_ROOT"/crosslingual/dictionaries/"$SRC_LANG"-"$TGT_LANG"."$VAL_SPLIT".txt;
    TRN_DICT_PATH="$DATA_ROOT"/crosslingual/dictionaries/"$SRC_LANG"-"$TGT_LANG"."$TRN_SPLIT".txt;
    TRN_SEED_DICT_PATH="$DATA_ROOT"/crosslingual/seed_dictionaries/"$SRC_LANG"-"$TGT_LANG"."$TRN_SPLIT".seed.txt;

    if [ "$PHASE" = 0 ]; then # preprocessing, not really necessary
        echo "preprocessing ... "
        mkdir -p $PRE_DATA_ROOT;
        
        # Run normalization
        python3 normalize_embeddings.py unit center -i $TGT_EMB_PATH -o $NORM_TGT_EMB_PATH --max_vocab $TRAIN_MAX_SIZE;
        python3 normalize_embeddings.py unit center -i $SRC_EMB_PATH -o $NORM_SRC_EMB_PATH --max_vocab $TRAIN_MAX_SIZE;

    elif [ "$PHASE" = 1 ]; then # train the mapping with full dictionary
        echo "training the mapping with full labels ... "
        for method_command in "${METHODS[@]}"
        do
            METHOD="${method_command%%:*}";
            COMMAND="${method_command##*:}";
            # echo "$METHOD" "$COMMAND"
            mkdir -p $SAVE_PATH/$METHOD
            MAPPED_TGT_EMB_PATH=$SAVE_PATH/$METHOD/wiki.$TGT_LANG.mapped.vec
            MAPPED_SRC_EMB_PATH=$SAVE_PATH/$METHOD/wiki.$SRC_LANG.mapped.vec
            if [ -f $MAPPED_SRC_EMB_PATH ]; then
                echo "$SRC_LANG $METHOD already exists!"
                continue;
            fi
            python3 map_embeddings.py $SRC_EMB_PATH $TGT_EMB_PATH $MAPPED_SRC_EMB_PATH $MAPPED_TGT_EMB_PATH --vocab_size $TRAIN_MAX_SIZE $COMMAND -d $TRN_DICT_PATH --validation $VAL_DICT_PATH --log $SAVE_PATH/$METHOD/logger.txt;
            # echo "$METHOD" "$COMMAND"
            # exit -1 
        done

    elif [ "$PHASE" = 2 ]; then #
        echo "training the mapping with partial labels ... "
        mkdir -p $SAVE_PATH/Artetxe17;
        MAPPED_TGT_EMB_PATH=$SAVE_PATH/Artetxe17/wiki.$TGT_LANG.mapped.vec
        MAPPED_SRC_EMB_PATH=$SAVE_PATH/Artetxe17/wiki.$SRC_LANG.mapped.vec
        if [ -f $MAPPED_SRC_EMB_PATH ]; then
            echo "$SRC_LANG: $MAPPED_SRC_EMB_PATH already exists!"
            continue;
        fi
        python3 map_embeddings.py $SRC_EMB_PATH $TGT_EMB_PATH $MAPPED_SRC_EMB_PATH $MAPPED_TGT_EMB_PATH --vocab_size $UNSUP_TRAIN_MAX_SIZE --trans_vocab_size $TRAIN_MAX_SIZE -d $TRN_SEED_DICT_PATH --orthogonal  --self_learning -v --validation $VAL_DICT_PATH --log $SAVE_PATH/Artetxe17/logger.txt --normalize unit center
    fi
done