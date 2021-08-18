include "../node_modules/circomlib/circuits/gates.circom"
include "../node_modules/circomlib/circuits/comparators.circom"

template AreWordEqual(WORD_SIZE) {
  signal input word[WORD_SIZE];
  signal input entry[WORD_SIZE];
  signal output out;

  component is_prefix_equal[WORD_SIZE];
  component is_word_equal[WORD_SIZE];

  for (var i = 0;i < WORD_SIZE;i++) {
    is_prefix_equal[i] = AND();
    is_word_equal[i] = IsEqual();
  }

  for (var i = 0;i < WORD_SIZE;i++) {
    is_word_equal[i].in[0] <== word[i];
    is_word_equal[i].in[1] <== entry[i];

    is_prefix_equal[i].a <== is_word_equal[i].out;
    is_prefix_equal[i].b <== (i == 0) ? 1 : is_prefix_equal[i-1].out;
  }

  out <== is_prefix_equal[WORD_SIZE-1].out;
}

template InDictionary(DICTIONARY_SIZE, WORD_SIZE) {
  signal input word[WORD_SIZE];
  signal input dictionary[DICTIONARY_SIZE][WORD_SIZE];
  signal output out;

  component in_prefix[DICTIONARY_SIZE];
  component is_equal[DICTIONARY_SIZE];

  for (var i = 0;i < DICTIONARY_SIZE;i++) {
    in_prefix[i] = OR();
    is_equal[i] = AreWordEqual(WORD_SIZE);
  }

  for (var i = 0;i < DICTIONARY_SIZE;i++) {
    for (var j = 0;j < WORD_SIZE;j++) {
      is_equal[i].word[j] <== word[j];
      is_equal[i].entry[j] <== dictionary[i][j];
    }

    in_prefix[i].a <== (i == 0) ? 0 : in_prefix[i-1].out;
    in_prefix[i].b <== is_equal[i].out;
  }

  out <== in_prefix[DICTIONARY_SIZE-1].out;
}

template IsWordValid(WORD_SIZE) {
  signal input word[WORD_SIZE];
  signal output out;

  component is_suffix_empty[WORD_SIZE];
  component is_suffix_valid[WORD_SIZE];
  component is_empty[WORD_SIZE];
  component is_nonempty[WORD_SIZE];
  component is_emptiness_valid[WORD_SIZE];

  for (var i = 0;i < WORD_SIZE;i++) {
    is_suffix_empty[i] = AND();
    is_suffix_valid[i] = AND();
    is_empty[i] = IsEqual();
    is_nonempty[i] = NOT();
    is_emptiness_valid[i] = OR();
  }

  for (var i = WORD_SIZE - 1;i >= 0;i--) {
    is_empty[i].in[0] <== word[i];
    is_empty[i].in[1] <== 27;
    is_nonempty[i].in <== is_empty[i].out;
    is_suffix_empty[i].a <== (i == WORD_SIZE - 1) ? 1 : is_suffix_empty[i+1].out;
    is_suffix_empty[i].b <== is_empty[i].out;

    is_emptiness_valid[i].a <== is_nonempty[i].out;
    is_emptiness_valid[i].b <== (i == WORD_SIZE - 1) ? 1 : is_suffix_empty[i+1].out;


    is_suffix_valid[i].a <== (i == WORD_SIZE - 1) ? 1 : is_suffix_valid[i+1].out;
    is_suffix_valid[i].b <== is_emptiness_valid[i].out;
  }

  out <== is_suffix_valid[0].out;
}

template IsPadding() {
  signal input first_char;
  signal output out;

  component is_padding = IsEqual();
  is_padding.in[0] <== first_char;
  is_padding.in[1] <== 28;

  out <== is_padding.out;
}
