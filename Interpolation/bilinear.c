// bilinear interpolation
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

	for (int i = 0; i < 128; i++)
		for (int j = 0; j < 128; j++)
			interpolated[j * 4][i * 4] = input[j][i];

	////////// Step 2. Input image에 bilinear interpolation //////////
	for (int j = 0; j < 512; j++) {
		for (int i = 0; i < 512; i += 4) {
			int mid_idx = (i + (i + 4)) / 2;
			interpolated[j][(mid_idx)] = (interpolated[j][i] + interpolated[j][i + 4]) / 2;
		}
	}

	for (int j = 0; j < 512; j++) {
		for (int i = 0; i < 512; i += 4) {
			int mid_idx = (i + (i + 4)) / 2;
			interpolated[mid_idx][j] = (interpolated[i][j] + interpolated[i + 4][j]) / 2;
		}
	}

	for (int j = 0; j < 512; j++) {
		for (int i = 0; i < 512; i += 2) {
			int mid_idx = (i + (i + 2)) / 2;
			interpolated[j][(mid_idx)] = (interpolated[j][i] + interpolated[j][i + 2]) / 2;
		}
	}

	for (int j = 0; j < 512; j++) {
		for (int i = 0; i < 512; i += 2) {
			int mid_idx = (i + (i + 2)) / 2;
			interpolated[mid_idx][j] = (interpolated[i][j] + interpolated[i + 2][j]) / 2;
		}
	}

	for (int i = 0; i < 512; i++) // 보간되지 않은 외각 채우기
		for (int j = 1; j < 4; j++)
		{
			interpolated[i][512 - j] = 2 * interpolated[i][512 - 4] - interpolated[i][512 - 2 * 4 + j];
			interpolated[512 - j][i] = 2 * interpolated[512 - 4][i] - interpolated[512 - 2 * 4 + j][i];
		}

	////////// Step 3. 보간된 512x512 image를 .raw 포맷 파일로 저장 //////////
	FILE* output_image = fopen("./output/bi_lena(512x512).raw", "wb");
	fwrite(interpolated, sizeof(unsigned char), 512 * 512, output_image);
	fclose(output_image);

	FILE* original_image = fopen("./input/lena(512x512).raw", "rb");
	if (!original_image)
		printf("File open error!\n");

	unsigned char original[512][512];
	fread(original, sizeof(unsigned char), 512 * 512, original_image);
	fclose(original_image);

	////////// Step 4. Interpolated image와 Original image 간 PSNR 측정 //////////
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
