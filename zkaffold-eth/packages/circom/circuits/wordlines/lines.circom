include "../../node_modules/circomlib/circuits/gates.circom"
include "../../node_modules/circomlib/circuits/comparators.circom"
include "words.circom"

template IsContinual(LINE_SIZE, WORD_SIZE, BIT_SIZE) {
	signal input words[LINE_SIZE][WORD_SIZE];
	signal input padding[LINE_SIZE];
	signal output out;

	component is_prefix_continual[LINE_SIZE];
	component is_index_continued[LINE_SIZE];
	component is_padding_or_continued[LINE_SIZE];
	component words_last_char[LINE_SIZE];

	for (var i = 0;i < LINE_SIZE;i++) {
		is_prefix_continual[i] = AND();
		is_index_continued[i] = IsEqual();
		is_padding_or_continued[i] = OR();
		words_last_char[i] = ExtractLastChar(WORD_SIZE, BIT_SIZE);
	}

	for (var i = 0;i < LINE_SIZE;i++) {
		for (var j = 0;j < WORD_SIZE;j++) {
			words_last_char[i].word[j] <== words[i][j];
		}
	}

	for (var i = 0;i < LINE_SIZE;i++) {
		is_index_continued[i].in[0] <== words[i][0];
		is_index_continued[i].in[1] <== (i == 0) ? words[i][0] : words_last_char[i-1].out;
		
		is_padding_or_continued[i].a <== is_index_continued[i].out;
		is_padding_or_continued[i].b <== padding[i];

		is_prefix_continual[i].a <== (i == 0) ? 1 : is_prefix_continual[i-1].out;
		is_prefix_continual[i].b <== is_padding_or_continued[i].out;
	}

	out <== is_prefix_continual[LINE_SIZE-1].out;
}
