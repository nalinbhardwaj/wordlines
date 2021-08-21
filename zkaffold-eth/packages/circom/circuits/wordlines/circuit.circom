include "words.circom"
include "lines.circom"

template Main(LINE_SIZE, WORD_SIZE, BIT_SIZE, COMPRESSED_DICTIONARY_SIZE, COMPRESSION_RATIO, DICTIONARY_SIZE, FIG_SIZE, SIDE_SIZE) {
  signal private input line[LINE_SIZE];
  signal private input private_address;
  signal input figure;
  signal input compressed_dictionary[COMPRESSED_DICTIONARY_SIZE];
  signal input address;

  component figure_extractor = CharExtractor(FIG_SIZE, BIT_SIZE);
  figure_extractor.poly <== figure;

  component dictionary = ExtractDictionary(COMPRESSED_DICTIONARY_SIZE, DICTIONARY_SIZE, WORD_SIZE, BIT_SIZE, COMPRESSION_RATIO);

  for (var i = 0;i < COMPRESSED_DICTIONARY_SIZE;i++) dictionary.in[i] <== compressed_dictionary[i];

  component extractor[LINE_SIZE];
  for (var i = 0;i < LINE_SIZE;i++) extractor[i] = CharExtractor(WORD_SIZE, BIT_SIZE);
  for (var i = 0;i < LINE_SIZE;i++) extractor[i].poly <== line[i];

  component figure_checker = CheckFigure(LINE_SIZE, WORD_SIZE, FIG_SIZE);
  for (var i = 0;i < FIG_SIZE;i++) figure_checker.fig[i] <== figure_extractor.out[i];
  for (var i = 0;i < LINE_SIZE;i++) {
    for (var j = 0;j < WORD_SIZE;j++) figure_checker.line[i][j] <== extractor[i].out[j];
  }
  figure_checker.out === 1;

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
      checker[i].dictionary[j] <== dictionary.out[j];
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
  private_address === address;
}

component main = Main(7, 6, 5, 90, 8, 720, 12, 3);
