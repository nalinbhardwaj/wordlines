include "../node_modules/circomlib/circuits/gates.circom"
include "../node_modules/circomlib/circuits/comparators.circom"

template IsContinual(LINE_SIZE, WORD_SIZE) {
	signal input words[LINE_SIZE][WORD_SIZE];
	signal input padding[LINE_SIZE];
	signal output out;

	component is_prefix_continual[LINE_SIZE];
	component is_index_continued[LINE_SIZE];
	component is_padding_or_continued[LINE_SIZE];

	for (var i = 0;i < LINE_SIZE;i++) {
		is_prefix_continual[i] = AND();
		is_index_continued[i] = IsEqual();
		is_padding_or_continued[i] = OR();
	}

	for (var i = 0;i < LINE_SIZE;i++) {
		is_index_continued[i].in[0] <== words[i][0];
		is_index_continued[i].in[1] <== (i == 0) ? words[i][0] : words[i-1][WORD_SIZE-1];
		
		is_padding_or_continued[i].a <== is_index_continued[i].out;
		is_padding_or_continued[i].b <== padding[i];

		is_prefix_continual[i].a <== (i == 0) ? 1 : is_prefix_continual[i-1].out;
		is_prefix_continual[i].b <== is_padding_or_continued[i].out;
	}

	out <== is_prefix_continual[LINE_SIZE-1].out;
}

template IsNotCrossing(WORD_SIZE, FIG_SIZE, SIDE_SIZE) {
	signal input word[WORD_SIZE];
	signal input figure[FIG_SIZE][SIDE_SIZE];
	signal output out;

	component are_all_not_crossing = MultiAND((WORD_SIZE-1)*FIG_SIZE*SIDE_SIZE*SIDE_SIZE);
	component is_char_same[WORD_SIZE-1][FIG_SIZE][SIDE_SIZE][SIDE_SIZE][2];
	component is_prefix_crossing[WORD_SIZE-1][FIG_SIZE][SIDE_SIZE][SIDE_SIZE];
	component is_prefix_not_crossing[WORD_SIZE-1][FIG_SIZE][SIDE_SIZE][SIDE_SIZE];

	for (var i = 0;i < WORD_SIZE-1;i++) {
		for (var j = 0;j < FIG_SIZE;j++) {
			for (var k = 0;k < SIDE_SIZE;k++) {
				for (var l = 0;l < SIDE_SIZE;l++) {
					for (var m = 0;m < 2;m++) is_char_same[i][j][k][l][m] = IsEqual();
					is_prefix_crossing[i][j][k][l] = AND();
					is_prefix_not_crossing[i][j][k][l] = NOT();
				}
			}
		}
	}

	var idx = 0;
	for (var i = 0;i < WORD_SIZE-1;i++) {
		for (var j = 0;j < FIG_SIZE;j++) {
			for (var k = 0;k < SIDE_SIZE;k++) {
				for (var l = 0;l < SIDE_SIZE;l++) {
					is_char_same[i][j][k][l][0].in[0] <== word[i];
					is_char_same[i][j][k][l][0].in[1] <== figure[j][k];
					is_char_same[i][j][k][l][1].in[0] <== word[i+1];
					is_char_same[i][j][k][l][1].in[1] <== figure[j][l];


					is_prefix_crossing[i][j][k][l].a <== is_char_same[i][j][k][l][0].out;
					is_prefix_crossing[i][j][k][l].b <== is_char_same[i][j][k][l][1].out;
					is_prefix_not_crossing[i][j][k][l].in <== is_prefix_crossing[i][j][k][l].out;
					are_all_not_crossing.in[idx] <== is_prefix_not_crossing[i][j][k][l].out;
					idx++;
				}
			}
		}
	}

	out <== are_all_not_crossing.out;
}
