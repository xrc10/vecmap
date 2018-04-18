# Run MUSE dataset

DATA_ROOT=data/MUSE/;
PRE_DATA_ROOT=data/MUSE_PRE/;
EVAL_ROOT=../EvaluateCLEMb/;

TGT_LANG=en
SEED_SIZE=200
TRN_SPLIT=5000-6500
VAL_SPLIT=0-5000
TRAIN_MAX_SIZE=200000

PHASE=1 # 0-preprocessing # 1-sup train mapping # 2-(nearly) unsup train mapping # 3-evaluate sup train # 4-evaluate unsup train

SRC_LANGS=(es fr de ru zh eo)
# SRC_LANGS=(bg ca da fi)

for i in 0 1 2 3
do
    SRC_LANG=${SRC_LANGS[$i]};
    echo $SRC_LANG;
    # Embedding Paths
    TGT_EMB_PATH=$DATA_ROOT/wiki.$TGT_LANG.vec
    NORM_TGT_EMB_PATH=$PRE_DATA_ROOT/wiki.$TGT_LANG.norm.vec
    SRC_EMB_PATH=$DATA_ROOT/wiki.$SRC_LANG.vec
    NORM_SRC_EMB_PATH=$PRE_DATA_ROOT/wiki.$SRC_LANG.norm.vec

    SAVE_PATH=save/MUSE/$SRC_LANG-$TGT_LANG/;

    # Dictionary paths
    VAL_DICT_PATH="$DATA_ROOT"/crosslingual/dictionaries/"$SRC_LANG"-"$TGT_LANG"."$VAL_SPLIT".txt;
    TRN_DICT_PATH="$DATA_ROOT"/crosslingual/dictionaries/"$SRC_LANG"-"$TGT_LANG"."$TRN_SPLIT".txt;

    if [ "$PHASE" = 0 ]; then # preprocessing
        echo "preprocessing ... "
        mkdir -p $PRE_DATA_ROOT;
        
        # Run normalization
        python3 normalize_embeddings.py unit center -i $TGT_EMB_PATH -o $NORM_TGT_EMB_PATH --max_vocab $TRAIN_MAX_SIZE;
        python3 normalize_embeddings.py unit center -i $SRC_EMB_PATH -o $NORM_SRC_EMB_PATH --max_vocab $TRAIN_MAX_SIZE;

    elif [ "$PHASE" = 1 ]; then # train the mapping with full dictionary
        echo "training the mapping with full labels ... "
        mkdir -p $SAVE_PATH/full
        MAPPED_TGT_EMB_PATH=$SAVE_PATH/full/wiki.$TGT_LANG.full.mapped.vec
        MAPPED_SRC_EMB_PATH=$SAVE_PATH/full/wiki.$SRC_LANG.full.mapped.vec
        python3 map_embeddings.py --orthogonal $NORM_SRC_EMB_PATH $NORM_TGT_EMB_PATH $MAPPED_SRC_EMB_PATH $MAPPED_TGT_EMB_PATH -d $TRN_DICT_PATH --validation $VAL_DICT_PATH --log $SAVE_PATH/full/logger.txt

    elif [ "$PHASE" = 2 ]; then #
        echo "training the mapping with partial labels ... "
        mkdir -p $SAVE_PATH/numerals;
        MAPPED_TGT_EMB_PATH=$SAVE_PATH/numerals/wiki.$TGT_LANG.numerals.mapped.vec
        MAPPED_SRC_EMB_PATH=$SAVE_PATH/numerals/wiki.$SRC_LANG.numerals.mapped.vec
        python3 map_embeddings.py --orthogonal $NORM_SRC_EMB_PATH $NORM_TGT_EMB_PATH $MAPPED_SRC_EMB_PATH $MAPPED_TGT_EMB_PATH --numerals --self_learning -v --validation $VAL_DICT_PATH --log $SAVE_PATH/full/logger.txt

    elif [ "$PHASE" = 3 ]; then #
        echo "evaluating ... "
        
        MAPPED_TGT_EMB_PATH=$SAVE_PATH/full/wiki.$TGT_LANG.full.mapped.vec
        MAPPED_SRC_EMB_PATH=$SAVE_PATH/full/wiki.$SRC_LANG.full.mapped.vec
        # python $EVAL_ROOT/evaluate_MUSE.py --src_lang $SRC_LANG --tgt_lang $TGT_LANG --tgt_emb $MAPPED_TGT_EMB_PATH --src_emb $MAPPED_SRC_EMB_PATH --max_vocab $TRAIN_MAX_SIZE --exp_path $SAVE_PATH/full --cuda 0;
        # python $EVAL_ROOT/find_nearest_neighbor.py --src_path $MAPPED_SRC_EMB_PATH --tgt_path $MAPPED_TGT_EMB_PATH --bi_dict_path $TRN_DICT_PATH &> $SAVE_PATH/full/find_nnr.log
        python $EVAL_ROOT/eval_knn_acc.py -src_emb_path $MAPPED_SRC_EMB_PATH -tgt_emb_path $MAPPED_TGT_EMB_PATH -dictionary $TRN_DICT_PATH &> $SAVE_PATH/full/eval_knn_acc.log


        
    elif [ "$PHASE" = 4 ]; then #
        echo "evaluating ... "
        
        MAPPED_TGT_EMB_PATH=$SAVE_PATH/numerals/wiki.$TGT_LANG.numerals.mapped.vec
        MAPPED_SRC_EMB_PATH=$SAVE_PATH/numerals/wiki.$SRC_LANG.numerals.mapped.vec
        # python E$EVAL_ROOT/evaluate_MUSE.py --src_lang $SRC_LANG --tgt_lang $TGT_LANG --tgt_emb $MAPPED_TGT_EMB_PATH --src_emb $MAPPED_SRC_EMB_PATH --max_vocab $TRAIN_MAX_SIZE --exp_path $SAVE_PATH/numerals --cuda 0;
        python $EVAL_ROOT/eval_knn_acc.py -src_emb_path $MAPPED_SRC_EMB_PATH -tgt_emb_path $MAPPED_TGT_EMB_PATH -dictionary $TRN_DICT_PATH &> $SAVE_PATH/full/eval_knn_acc.log
    fi
done