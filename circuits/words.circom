include "../node_modules/circomlib/circuits/bitify.circom"
include "../node_modules/circomlib/circuits/gates.circom"
include "../node_modules/circomlib/circuits/comparators.circom"

template InDictionary(DICTIONARY_SIZE) {
  signal input word;
  signal input dictionary[DICTIONARY_SIZE];
  signal output out;

  component in_prefix[DICTIONARY_SIZE];
  component is_equal[DICTIONARY_SIZE];

  for (var i = 0;i < DICTIONARY_SIZE;i++) {
    in_prefix[i] = OR();
    is_equal[i] = IsEqual();
  }

  for (var i = 0;i < DICTIONARY_SIZE;i++) {
    is_equal[i].in[0] <== word;
    is_equal[i].in[1] <== dictionary[i];

    in_prefix[i].a <== (i == 0) ? 0 : in_prefix[i-1].out;
    in_prefix[i].b <== is_equal[i].out;
  }

  out <== in_prefix[DICTIONARY_SIZE-1].out;
}

template IsPadding() {
  signal input first_char;
  signal output out;

  component is_padding = IsEqual();
  is_padding.in[0] <== first_char;
  is_padding.in[1] <== 28;

  out <== is_padding.out;
}

template ExtractLastChar(WORD_SIZE, BIT_SIZE) {
  signal input word[WORD_SIZE];
  signal output out;

  // here lie dragons
  component is_suffix_padding[WORD_SIZE];
  component is_index_padding[WORD_SIZE];
  component does_prefix_have_padding[WORD_SIZE];
  component does_prefix_not_have_padding[WORD_SIZE];
  for (var i = 0;i < WORD_SIZE;i++) {
    is_suffix_padding[i] = AND();
    is_index_padding[i] = IsEqual();
    does_prefix_have_padding[i] = OR();
    does_prefix_not_have_padding[i] = NOT();
  }

  for (var i = 0;i < WORD_SIZE;i++) {
    is_index_padding[i].in[0] <== word[i];
    is_index_padding[i].in[1] <== 27;
    
    does_prefix_have_padding[i].a <== (i == 0) ? 0 : does_prefix_have_padding[i-1].out;
    does_prefix_have_padding[i].b <== is_index_padding[i].out;
    does_prefix_not_have_padding[i].in <== does_prefix_have_padding[i].out;
  }

  for (var i = WORD_SIZE-1;i >= 0;i--) {
    is_suffix_padding[i].a <== (i == WORD_SIZE-1) ? 1 : is_suffix_padding[i+1].out;
    is_suffix_padding[i].b <== is_index_padding[i].out;
  }

  component bitified[WORD_SIZE];
  for (var i = 0;i < WORD_SIZE;i++) bitified[i] = Num2Bits(BIT_SIZE);
  for (var i = 0;i < WORD_SIZE;i++) bitified[i].in <== word[i];
  component modded_bitified[WORD_SIZE][BIT_SIZE];
  for (var i = 0;i < WORD_SIZE;i++) {
    for (var j = 0;j < BIT_SIZE;j++) modded_bitified[i][j] = MultiAND(3);
  }
  for (var i = 0;i < WORD_SIZE;i++) {
    for (var j = 0;j < BIT_SIZE;j++) {
      modded_bitified[i][j].in[0] <== bitified[i].out[j];
      modded_bitified[i][j].in[1] <== (i == WORD_SIZE-1) ? 1 : is_suffix_padding[i+1].out;
      modded_bitified[i][j].in[2] <== does_prefix_not_have_padding[i].out;
    }
  }

  component prefix_bitified[WORD_SIZE][BIT_SIZE];
  for (var i = 0;i < WORD_SIZE;i++) {
    for (var j = 0;j < BIT_SIZE;j++) prefix_bitified[i][j] = OR();
  }

  for (var i = 0;i < WORD_SIZE;i++) {
    for (var j = 0;j < BIT_SIZE;j++) {
      prefix_bitified[i][j].a <== (i == 0) ? 0 : prefix_bitified[i-1][j].out;
      prefix_bitified[i][j].b <== modded_bitified[i][j].out;
    }
  }

  component result = Bits2Num(BIT_SIZE);
  for (var i = 0;i < BIT_SIZE;i++) result.in[i] <== prefix_bitified[WORD_SIZE-1][i].out;

  out <== result.out;
}

template CharExtractor(WORD_SIZE, BIT_SIZE) {
  signal input poly;
  signal output out[WORD_SIZE];

  component bitified = Num2Bits(WORD_SIZE*BIT_SIZE);
  bitified.in <== poly;

  component numified[WORD_SIZE]
  for (var i = 0;i < WORD_SIZE;i++) numified[i] = Bits2Num(BIT_SIZE);
  for (var i = 0;i < WORD_SIZE;i++) {
    for (var j = 0;j < BIT_SIZE;j++) {
      numified[WORD_SIZE - i - 1].in[j] <== bitified.out[i*BIT_SIZE + j];
    }
  }

  for (var i = 0;i < WORD_SIZE;i++) out[i] <== numified[i].out;
}
