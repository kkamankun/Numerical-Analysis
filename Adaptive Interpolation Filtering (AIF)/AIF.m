clearvars; % 작업 공간 지우기

fin=fopen('./lena(256x256).raw','r'); % downsampled 영상(256x256) 읽기
down=fread(fin, [256 256]);
fclose(fin);

H = [0 -1 0; 0 2 0;0 -1 0]; % 라플라시안 마스크
V = [0 0 0; -1 2 -1; 0 0 0];
D135 = [-1 0 0; 0 2 0; 0 0 -1];
D45 = [0 0 -1; 0 2 0; -1 0 0];

% 픽셀 분류(블럭 1개에 픽셀 4개)
classOfBlocks = zeros(1,4096); % 각 블럭의 클래스 정보를 저장
a = 1;
for i = 1:4:256
    for j = 1:4:256
        block = down(i:i+3,j:j+3); % 4x4
        h = abs(sum(block(1:3,1:3).*H, 'all')) + abs(sum(block(2:4,1:3).*H, 'all')) + abs(sum(block(1:3,2:4).*H, 'all')) + abs(sum(block(2:4,2:4).*H, 'all'));
        v = abs(sum(block(1:3,1:3).*V, 'all')) + abs(sum(block(2:4,1:3).*V, 'all')) + abs(sum(block(1:3,2:4).*V, 'all')) + abs(sum(block(2:4,2:4).*V, 'all'));
        d135 = abs(sum(block(1:3,1:3).*D135, 'all')) + abs(sum(block(2:4,1:3).*D135, 'all')) + abs(sum(block(1:3,2:4).*D135, 'all')) + abs(sum(block(2:4,2:4).*D135, 'all'));
        d45 = abs(sum(block(1:3,1:3).*D45, 'all')) + abs(sum(block(2:4,1:3).*D45, 'all')) + abs(sum(block(1:3,2:4).*D45, 'all')) + abs(sum(block(2:4,2:4).*D45, 'all'));
        
        dir = [10 h v d135 d45]; % 방향성 결정
        dirOfBlock = find(dir==max([10 h v d135 d45]));
        
        act = h + v; % 활동성 결정
        actOfBlock = fix(act / 204);
        
        class = actOfBlock*5 + dirOfBlock(1); % 클래스 결정
        
        classOfBlocks(1,a) = class;
        a = a + 1;
    end
end

% 6-tap
recon=zeros(512, 512);
for i = 1:1:256
    for j = 1:1:256
        recon(i*2,j*2) = down(i,j); % integer-pel
    end
end

for k = 2:2:502
    for j = 2:2:502
        for i = 0:2:10 % 수평방향(half-pel)
            recon(k+i,j+5) = ((11 * recon(k + i,j)) - (43 * recon(k + i,j + 2)) + (160 * recon(k + i,j + 4))	+ (160 * recon(k + i,j + 6)) - (43 * recon(k + i,j + 8)) + (11 * recon(k + i,j + 10))) / 256;
        end
        for i = 0:2:10 % 수직방향(half-pel)
            recon(k+ 5,j + i) = ((11 * recon(k,j + i)) - (43 * recon(k + 2,j + i)) + (160 * recon(k + 4,j + i)) + (160 * recon(k + 6,j + i)) - (43 * recon(k + 8,j + i)) + (11 * recon(k + 10,j + i))) / 256;
        end
        recon(k + 5,j + 5) = ((11 * recon(k + 5,j)) - (43 * recon(k + 5,j + 2)) + (160 * recon(k + 5,j + 4)) + (160 * recon(k + 5,j + 6)) - (43 * recon(k + 5,j + 8)) + (11 * recon(k + 5,j + 10))) / 256; % j
    end
end

% 보간되지 않은 외곽 영역 채우기 (zero padding)
for i = 2:2:512
    recon(1,i) = ((160 * recon(2,i)) - (43 * recon(4,i)) + (11 * recon(6,i))) / 256;
    recon(3,i) = ((160 * recon(2,i)) + (160 * recon(4,i)) - (43 * recon(6,i)) + (11 * recon(8,i))) / 256;
    recon(5,i) = ((-(43 * recon(2,i))) + (160 * recon(4,i)) + (160 * recon(6,i)) - (43 * recon(8,i)) + (11 * recon(10,i))) / 256;
    recon(509,i) = (-(43 * recon(512,i)) + (160 * recon(510,i)) + (160 * recon(508,i)) - (43 * recon(506,i)) + (11 * recon(504,i))) / 256;
    recon(511,i) = ((160 * recon(512,i)) + (160 * recon(510,i)) - (43 * recon(508,i)) + (11 * recon(506,i))) / 256;
    recon(i,1) = ((160 * recon(i,2)) - (43 * recon(i,4)) + (11 * recon(i,6))) / 256;
    recon(i,3) = ((160 * recon(i,2)) + (160 * recon(i,4)) - (43 * recon(i,6)) + (11 * recon(i,8))) / 256;
    recon(i,5) = ((-(43 * recon(i,2))) + (160 * recon(i,4)) + (160 * recon(i,6)) - (43 * recon(i,8)) + (11 * recon(i,10))) / 256;
    recon(i,509) = (-(43 * recon(i,512)) + (160 * recon(i,510)) + (160 * recon(i,508)) - (43 * recon(i,506)) + (11 * recon(i,504))) / 256;
    recon(i,511) = ((160 * recon(i,512)) + (160 * recon(i,510)) - (43 * recon(i,508)) + (11 * recon(i,506))) / 256;
end
for i = 3:2:512
    recon(1,i) = (recon(1,i - 1) + recon(1,i + 1)) / 2;
    recon(3,i) = (recon(3,i - 1) + recon(3,i + 1)) / 2;
    recon(5,i) = (recon(5,i - 1) + recon(5,i + 1)) / 2;
    recon(509,i) = (recon(509,i - 1) + recon(509,i + 1)) / 2;
    recon(511,i) = (recon(511,i - 1) + recon(511,i + 1)) / 2;
    recon(i,1) = (recon(i - 1,1) + recon(i + 1,1)) / 2;
    recon(i,3) = (recon(i - 1,3) + recon(i + 1,3)) / 2;
    recon(i,5) = (recon(i - 1,5) + recon(i + 1,5)) / 2;
    recon(i,509) = (recon(i - 1,509) + recon(i + 1,509)) / 2;
    recon(i,511) = (recon(i - 1,511) + recon(i + 1,511)) / 2;
end
recon(1,1)=recon(1,2);

fout=fopen('./6-tap_lena(512x512).raw', 'wb'); % 6-tap 필터로 보간된 영상 저장
fwrite(fout, recon);
fclose(fout);

% PSNR
fin2=fopen('./lena(512x512).raw','r'); % 원본 영상(512x512) 읽기
ori=fread(fin2, [512 512]);
fclose(fin2);

N = 512*512;
sum = 0;
for i = 1:1:512
    for j = 1:1:512
        error = ori(i,j)-recon(i,j);
        sum = sum + error*error;
    end
end
mse = sum/N;
psnr = 20*log10(255/sqrt(mse));
psnr
