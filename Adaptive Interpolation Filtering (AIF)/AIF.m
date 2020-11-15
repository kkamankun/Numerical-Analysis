% paddarray() 함수 사용을 위해서 Image Processing Toolbox를 설치
clearvars; % 작업 공간 지우기

fin=fopen('./lena(256x256)_3.raw','r'); % downsampled 영상(256x256) 읽기
down=fread(fin, [256 256]);
fclose(fin);

H = [-1 -1 -1; 2 2 2;-1 -1 -1]; % 0도
V = [-1 2 -1; -1 2 -1; -1 2 -1]; % 90도
D135 = [2 -1 -1; -1 2 -1; -1 -1 2]; % 135도
D45 = [-1 -1 2; -1 2 -1; 2 -1 -1]; % 45도

% Pixel Classification (블럭 1개에 픽셀 4개)
act = zeros(1,4096); % 각 블럭의 활동성 저장
dirOfBlock = zeros(1,4096); % 각 블럭의 방향성 저장
for i = 1:4:256 % 행
    for j = 1:4:256 % 열
        block = down(i:i+3,j:j+3); % 4x4
        h = abs(sum(block(1:3,1:3).*H, 'all')) + abs(sum(block(2:4,1:3).*H, 'all')) + abs(sum(block(1:3,2:4).*H, 'all')) + abs(sum(block(2:4,2:4).*H, 'all'));
        v = abs(sum(block(1:3,1:3).*V, 'all')) + abs(sum(block(2:4,1:3).*V, 'all')) + abs(sum(block(1:3,2:4).*V, 'all')) + abs(sum(block(2:4,2:4).*V, 'all'));
        d135 = abs(sum(block(1:3,1:3).*D135, 'all')) + abs(sum(block(2:4,1:3).*D135, 'all')) + abs(sum(block(1:3,2:4).*D135, 'all')) + abs(sum(block(2:4,2:4).*D135, 'all'));
        d45 = abs(sum(block(1:3,1:3).*D45, 'all')) + abs(sum(block(2:4,1:3).*D45, 'all')) + abs(sum(block(1:3,2:4).*D45, 'all')) + abs(sum(block(2:4,2:4).*D45, 'all'));
        
        [M, I] = max([0 h v d135 d45]); % 방향성 결정
        dirOfBlock(64*((i+3)/4 - 1)+(j+3)/4) = I - 1;
        
        act(64*((i+3)/4 - 1)+(j+3)/4) = h + v + d135 + d45; % 각 블럭의 활동성 저장
    end
end
actOfBlock = fix(act/(round(max(act)/5)+1)); % 활동성 맵핑 (양자화)
classOfBlocks = actOfBlock*5 + dirOfBlock; % 각 블럭의 클래스 정보 저장 (0~24)

fin2=fopen('./lena(512x512).raw','r'); % 원본 영상(512x512) 읽기
ori=fread(fin2, [512 512]);
fclose(fin2);
up = imresize(down, 2, 'box');

% 적응형 보간 필터 최적화
wc_h = zeros(4,100); % 각 클래스별 optimized horizontal filter
wc_v = zeros(4,100); % 각 클래스별 optimized vertical filter
for i = 1:8:512 % 행
    for j = 1:8:512 % 열
        for k = 1:2:8
            x_h = up(i+(k-1), [j j+2 j+4 j+6]);
            x_v = up([i i+2 i+4 i+6], j+(k-1)).';
            y_h = ori(i+(k-1), [j j+2 j+4 j+6]);
            y_v = ori([i i+2 i+4 i+6], j+(k-1)).';
            wc_h_tmp = pinv(x_h.'*x_h)*x_h.'*y_h;
            wc_v_tmp = pinv(x_v.'*x_v)*x_v.'*y_v;
            c = classOfBlocks(64*((i+7)/8 - 1)+(j+7)/8);
            wc_h(1:4,1+4*c:4+4*c) =  wc_h(1:4,1+4*c:4+4*c) + wc_h_tmp;
            wc_v(1:4,1+4*c:4+4*c) =  wc_v(1:4,1+4*c:4+4*c) + wc_v_tmp;
        end
    end
end

for c =0:1:24
    cnt = sum(classOfBlocks==c);
    if cnt ~= 0
        wc_h(1:4,1+4*c:4+4*c) = wc_h(1:4,1+4*c:4+4*c)/(cnt*4);
        wc_v(1:4,1+4*c:4+4*c) = wc_v(1:4,1+4*c:4+4*c)/(cnt*4);
    end
end

% 적응형 보간 필터 적용
aif = up;
for i = 1:8:512 % 행
    for j = 1:8:512 % 열
        c = classOfBlocks(64*((i+7)/8 - 1)+(j+7)/8);
        for k = 1:2:8 % 수평 방향
            aif(i+(k-1),[j j+2 j+4 j+6]) = aif(i+(k-1),[j j+2 j+4 j+6])*wc_h(1:4,1+4*c:4+4*c);
        end
        for l = 1:1:8 % 수직 방향
            aif([i i+2 i+4 i+6], j+(l-1)) = ((aif([i i+2 i+4 i+6], j+(l-1))).'*wc_v(1:4,1+4*c:4+4*c)).';
        end
    end
end

fout = fopen('./AIF_lena(512x512).raw', 'wb'); % AIF 필터로 보간된 영상 저장
fwrite(fout, aif);
fclose(fout);

% 6-tap 필터 적용
tap = up;
padded = padarray(tap,[4,4],'replicate');
sinc = [11 -43 160 160 -43 11];
for i = 1:8:512 % 행
    for j = 1:8:512 % 열
        for k = 1:2:8 % 수평방향(half-pel)
            padded(k+i+3, j+5) = round((padded(i+k+3, [j j+2 j+4 j+6 j+8 j+10])*sinc.')/256);
        end
        for l = 1:1:8 % 수직방향(half-pel)
            padded(i+5, j+l+3) = round((padded([i i+2 i+4 i+6 i+8 i+10], j+l+3).'*sinc.')/256);
        end
    end
end
tap = padded(5:516,5:516);

fout=fopen('./6-tap_lena(512x512).raw', 'wb'); % 6-tap 필터로 보간된 영상 저장
fwrite(fout, tap);
fclose(fout);

% Squared Error가 낮은 필터를 결정해서 보간
sumAIF = 0;
sumTap = 0;
for i = 1:8:512 % 행
    for j = 1:8:512 % 열
        for k = 1:2:8
            errorAIF = ori(i+k,j+k) - aif(i+k,j+k);
            sumAIF = sumAIF + errorAIF*errorAIF;
            errorTap = ori(i+k,j+k) - tap(i+k,j+k);
            sumTap = sumTap + errorTap*errorTap;
            if sumAIF < sumTap
                recon(i:i+7,j:j+7) = tap(i:i+7,j:j+7);
            else
                recon(i:i+7,j:j+7) = aif(i:i+7,j:j+7);
            end
        end
    end
end
        
fout=fopen('./recon_lena(512x512).raw', 'wb'); % 6-tap 필터로 보간된 영상 저장
fwrite(fout, recon);
fclose(fout);        
        
% PSNR
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
