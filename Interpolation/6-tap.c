// 6-tab interpolation
#include <stdio.h>
#include <math.h>

int main(void)
{
	////////// Step 1. 128x128 image를 읽어서 메모리에 저장 //////////
	FILE* input_image = fopen("./input/lena(128x128).raw", "rb");
	if (!input_image)
		printf("File open error!\n");

	unsigned char input[128][128];
	fread(input, sizeof(unsigned char), 128 * 128, input_image);
	fclose(input_image);

	unsigned char interpolated[512][512];
	memset(interpolated, 0, sizeof(unsigned char) * 512 * 512);

	for (int i = 0; i < 128; i++)
		for (int j = 0; j < 128; j++)
			interpolated[i * 4][j * 4] = input[i][j];

	////////// Step 2. Input image에 6-tap interpolation //////////
	for (int k = 0; k < 512 - 20; k += 4) {
		for (int j = 0; j < 512 - 20; j += 4) {
			for (int i = 0; i <= 20; i += 4) { // 수직방향 (half-pel)
				interpolated[k + i][j + 10] = ((1 * interpolated[k + i][j]) - (5 * interpolated[k + i][j + 4]) + (20 * interpolated[k + i][j + 8])
					+ (20 * interpolated[k + i][j + 12]) - (5 * interpolated[k + i][j + 16]) + (1 * interpolated[k + i][j + 20])) >> 5;
			}

			for (int i = 0; i <= 20; i += 4) { // 수평방향 (half-pel)
				interpolated[k + 10][j + i] = ((1 * interpolated[k][j + i]) - (5 * interpolated[k + 4][j + i]) + (20 * interpolated[k + 8][j + i])
					+ (20 * interpolated[k + 12][j + i]) - (5 * interpolated[k + 16][j + i]) + (1 * interpolated[k + 20][j + i])) >> 5;
			}

			interpolated[k + 10][j + 10] = ((1 * interpolated[k + 10][j]) - (5 * interpolated[k + 10][j + 4]) + (20 * interpolated[k + 10][j + 8])
				+ (20 * interpolated[k + 10][j + 12]) - (5 * interpolated[k + 10][j + 16]) + (1 * interpolated[k + 10][j + 20])) >> 5; // j

			// 수평 방향 (quarter-pel)
			interpolated[k + 8][j + 9] = (interpolated[k + 8][j + 8] + interpolated[k + 8][j + 10]) / 2; // a = (G+b)/2
			interpolated[k + 8][j + 11] = (interpolated[k + 8][j + 10] + interpolated[k + 8][j + 12]) / 2; // c = (b+H)/2
			interpolated[k + 10][j + 9] = (interpolated[k + 10][j + 8] + interpolated[k + 10][j + 10]) / 2; // i = (h+j)/2
			interpolated[k + 10][j + 11] = (interpolated[k + 10][j + 10] + interpolated[k + 10][j + 12]) / 2; // k = (j+m)/2

			// 수직 방향 (quarter-pel)
			interpolated[k + 9][j + 8] = (interpolated[k + 8][j + 8] + interpolated[k + 10][j + 8]) / 2; // d = (G+h)/2
			interpolated[k + 9][j + 10] = (interpolated[k + 8][j + 10] + interpolated[k + 10][j + 10]) / 2; // f = (b+j)/2
			interpolated[k + 11][j + 8] = (interpolated[k + 10][j + 8] + interpolated[k + 12][j + 8]) / 2; // n = (h+M)/2
			interpolated[k + 11][j + 10] = (interpolated[k + 10][j + 10] + interpolated[k + 12][j + 10]) / 2; // q = (j+s)/2

			// 대각선 방향 (quarter-pel)
			interpolated[k + 9][j + 9] = (interpolated[k + 8][j + 10] + interpolated[k + 10][j + 8]) / 2; // e = (b+h)/2
			interpolated[k + 9][j + 11] = (interpolated[k + 8][j + 10] + interpolated[k + 10][j + 12]) / 2; // g = (b+m)/2
			interpolated[k + 11][j + 9] = (interpolated[k + 10][j + 8] + interpolated[k + 12][j + 10]) / 2; // p = (h+s)/2
			interpolated[k + 11][j + 11] = (interpolated[k + 10][j + 12] + interpolated[k + 12][j + 10]) / 2; // r = (m+s)/2
		}
	}

	// 보간되지 않은 외각 채우기
	for (int i = 0; i < 512; i += 2) {
		interpolated[2][i] = ((16 * interpolated[0][i]) + (20 * interpolated[4][i]) - (5 * interpolated[8][i])
			+ (1 * interpolated[12][i])) >> 5;
		interpolated[6][i] = ((- (4 * interpolated[0][i])) + (20 * interpolated[4][i]) + (20 * interpolated[8][i])
			- (5 * interpolated[12][i]) + (1 * interpolated[16][i])) >> 5;

		interpolated[506][i] = ((16 * interpolated[508][i]) + (20 * interpolated[504][i]) - (5 * interpolated[500][i])
			+ (1 * interpolated[496][i])) >> 5;
		interpolated[502][i] = (-(5 * interpolated[508][i]) + (21 * interpolated[504][i]) + (20 * interpolated[500][i])
			- (5 * interpolated[496][i]) + (1 * interpolated[492][i])) >> 5;

		interpolated[i][2] = ((16 * interpolated[i][0]) + (20 * interpolated[i][4]) - (5 * interpolated[i][8]) + (1 * interpolated[i][12])) >> 5;
		interpolated[i][6] = (-(4 * interpolated[i][0]) + (20 * interpolated[i][4]) + (20 * interpolated[i][8]) - (5 * interpolated[i][12]) + (1 * interpolated[i][16])) >> 5;

		interpolated[i][506] = ((16 * interpolated[i][508]) + (20 * interpolated[i][504]) - (5 * interpolated[i][500]) + (interpolated[i][496])) >> 5;
		interpolated[i][502] = (-(4 * interpolated[i][508]) + (20 * interpolated[i][504]) + (20 * interpolated[i][500]) - (5 * interpolated[i][496]) + (1 * interpolated[i][492])) >> 5;
	}

	for (int i = 0; i < 512; i += 2){
		for (int j = 1; j < 8; j += 2){
			interpolated[i][j] = (interpolated[i][j - 1] + interpolated[i][j + 1]) / 2;
			interpolated[j][i] = (interpolated[j - 1][i] + interpolated[j + 1][i]) / 2;
			interpolated[i][512 - 4 - j] = (interpolated[i][512 - 3 - j] + interpolated[i][512 - 5 - j]) / 2;
			interpolated[512 - 4 - j][i] = (interpolated[512 - 3 - j][i] + interpolated[512 - 5 - j][i]) / 2;
		}
	}
	for (int i = 1; i < 512 - 1; i += 2){
		for (int j = 0; j < 8; j += 2){
			interpolated[i][j] = (interpolated[i - 1][j] + interpolated[i + 1][j]) / 2;
			interpolated[j][i] = (interpolated[j][i - 1] + interpolated[j][i + 1]) / 2;
		}
	}
	for (int i = 1; i < 512 - 1; i += 2){
		for (int j = 512 - 4; j > 512 - 13; j -= 2){
			interpolated[i][j] = (interpolated[i - 1][j] + interpolated[i + 1][j]) / 2;
			interpolated[j][i] = (interpolated[j][i - 1] + interpolated[j][i + 1]) / 2;
		}
	}

	for (int i = 1; i < 512 - 1; i += 2){
		for (int j = 1; j < 8; j += 2){
			interpolated[i][j] = (interpolated[i - 1][j - 1] + interpolated[i + 1][j + 1]) / 2;
			interpolated[j][i] = (interpolated[j - 1][i - 1] + interpolated[j + 1][i + 1]) / 2;
			interpolated[i][512 - 4 - j] = (interpolated[i - 1][512 - 3 - j] + interpolated[i + 1][512 - 5 - j]) / 2;
			interpolated[512 - 4 - j][i] = (interpolated[512 - 3 - j][i - 1] + interpolated[512 - 5 - j][i + 1]) / 2;
		}
	}

	for (int i = 0; i < 512; i++)
	{
		interpolated[i][510] = (36 * interpolated[i][508] - 5 * interpolated[i][504] + interpolated[i][500]) >> 5;
		interpolated[510][i] = (36 * interpolated[508][i] - 5 * interpolated[504][i] + interpolated[500][i]) >> 5;
	}
	for (int i = 0; i < 512; i++)
	{
		interpolated[i][509] = (interpolated[i][510] + 31 * interpolated[i][508]) >> 5;
		interpolated[509][i] = (interpolated[510][i] + 31 * interpolated[508][i]) >> 5;
	}
	for (int i = 0; i < 512; i++)
	{
		interpolated[i][511] = 2 * interpolated[i][510] - interpolated[i][509];
		interpolated[511][i] = 2 * interpolated[510][i] - interpolated[509][i];
	}

	////////// Step 3. 보간된 512x512 image를 .raw 포맷 파일로 저장 //////////
	FILE* output_image = fopen("./output/6-tap_lena(512x512).raw", "wb");
	fwrite(interpolated, sizeof(unsigned char), 512 * 512, output_image);
	fclose(output_image);

	////////// Step 4. Interpolated image와 Original image 간 PSNR 측정 //////////
	FILE* original_image = fopen("./input/lena(512x512).raw", "rb");
	if (!original_image)
		printf("File open error!\n");

	unsigned char original[512][512];
	fread(original, sizeof(unsigned char), 512 * 512, original_image);
	fclose(original_image);

	int N = 512 * 512;
	int error;
	double mse, psnr, sum = 0;

	for (int i = 0; i < 512; i++)
	{
		for (int j = 0; j < 512; j++)
		{
			error = original[i][j] - interpolated[i][j];
			sum += error * error;
		}
	}
	mse = sum / N;
	psnr = 20 * log10(255 / sqrt(mse));
	printf("RMS는 %f입니다.\n", sqrt(mse));
	printf("PSNR은 %f입니다.\n", psnr);
	return 0;

} // end of main
