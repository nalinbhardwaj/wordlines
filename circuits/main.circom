include "words.circom"
include "lines.circom"

template Main(LINE_SIZE, DICTIONARY_SIZE, WORD_SIZE, FIG_SIZE, SIDE_SIZE) {
  signal private input line[LINE_SIZE][WORD_SIZE];
  signal input figure[FIG_SIZE][SIDE_SIZE];
  signal input dictionary[DICTIONARY_SIZE][WORD_SIZE];

  component is_padding[LINE_SIZE];
  for (var i = 0;i < LINE_SIZE;i++) is_padding[i] = IsPadding();
  for (var i = 0;i < LINE_SIZE;i++) {
    is_padding[i].first_char <== line[i][0];
  }

  component validator[LINE_SIZE];
  component validator_or_padding[LINE_SIZE];
  for (var i = 0;i < LINE_SIZE;i++) {
    validator[i] = IsWordValid(WORD_SIZE);
    validator_or_padding[i] = OR();
  }
  for (var i = 0;i < LINE_SIZE;i++) {
    for (var j = 0;j < WORD_SIZE;j++) validator[i].word[j] <== line[i][j];
    validator_or_padding[i].a <== validator[i].out;
    validator_or_padding[i].b <== is_padding[i].out;
    validator_or_padding[i].out === 1;
  }

  component checker[LINE_SIZE];
  component checker_or_padding[LINE_SIZE];
  for (var i = 0;i < LINE_SIZE;i++) {
    checker[i] = InDictionary(DICTIONARY_SIZE, WORD_SIZE);
    checker_or_padding[i] = OR();
  }
  for (var i = 0;i < LINE_SIZE;i++) {
    for (var j = 0;j < DICTIONARY_SIZE;j++) {
      for (var k = 0;k < WORD_SIZE;k++) {
        checker[i].dictionary[j][k] <== dictionary[j][k];
      }
    }

    for (var j = 0;j < WORD_SIZE;j++) {
        checker[i].word[j] <== line[i][j];
    }
    checker_or_padding[i].a <== checker[i].out;
    checker_or_padding[i].b <== is_padding[i].out;
    checker_or_padding[i].out === 1;
  }

  component continuity = IsContinual(LINE_SIZE, WORD_SIZE);
  for (var i = 0;i < LINE_SIZE;i++) {
    continuity.padding[i] <== is_padding[i].out;
    for (var j = 0;j < WORD_SIZE;j++) continuity.words[i][j] <== line[i][j];
  }
  continuity.out === 1;

  component crossing[LINE_SIZE];
  component crossing_or_padding[LINE_SIZE];
  for (var i = 0;i < LINE_SIZE;i++) {
    crossing[i] = IsNotCrossing(WORD_SIZE, FIG_SIZE, SIDE_SIZE);
    crossing_or_padding[i] = OR();
  }
  for (var i = 0;i < LINE_SIZE;i++) {
    for (var j = 0;j < WORD_SIZE;j++) crossing[i].word[j] <== line[i][j];
    for (var j = 0;j < FIG_SIZE;j++) {
      for (var k = 0;k < SIDE_SIZE;k++) crossing[i].figure[j][k] <== figure[j][k];
    }
    crossing_or_padding[i].a <== crossing[i].out;
    crossing_or_padding[i].b <== is_padding[i].out;
    crossing_or_padding[i].out === 1;
  }
}

component main = Main(3, 3, 3, 3, 2);
