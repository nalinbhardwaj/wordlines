include "words.circom"
include "lines.circom"

template Main(LINE_SIZE, WORD_SIZE, BIT_SIZE, DICTIONARY_SIZE, FIG_SIZE, SIDE_SIZE) {
  signal private input line[LINE_SIZE];
  signal input dictionary[DICTIONARY_SIZE];

  component extractor[LINE_SIZE];
  for (var i = 0;i < LINE_SIZE;i++) extractor[i] = CharExtractor(WORD_SIZE, 5);
  for (var i = 0;i < LINE_SIZE;i++) extractor[i].poly <== line[i];

  component is_padding[LINE_SIZE];
  for (var i = 0;i < LINE_SIZE;i++) is_padding[i] = IsPadding();
  for (var i = 0;i < LINE_SIZE;i++) {
    is_padding[i].first_char <== extractor[i].out[0];
  }

  component checker[LINE_SIZE];
  component checker_or_padding[LINE_SIZE];
  for (var i = 0;i < LINE_SIZE;i++) {
    checker[i] = InDictionary(DICTIONARY_SIZE);
    checker_or_padding[i] = OR();
  }
  for (var i = 0;i < LINE_SIZE;i++) {
    for (var j = 0;j < DICTIONARY_SIZE;j++) {
      checker[i].dictionary[j] <== dictionary[j];
    }

    checker[i].word <== line[i];
    checker_or_padding[i].a <== checker[i].out;
    checker_or_padding[i].b <== is_padding[i].out;
    checker_or_padding[i].out === 1;
  }

  component continuity = IsContinual(LINE_SIZE, WORD_SIZE, BIT_SIZE);
  for (var i = 0;i < LINE_SIZE;i++) {
    continuity.padding[i] <== is_padding[i].out;
    for (var j = 0;j < WORD_SIZE;j++) continuity.words[i][j] <== extractor[i].out[j];
  }
  continuity.out === 1;
}

component main = Main(7, 6, 5, 1000, 4, 3);
