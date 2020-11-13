classOfBlocks = zeros(1,4096); % 각 블럭의 클래스 정보를 저장
fin=fopen('./lena(256x256).raw','r');
ori=fread(fin, [256 256]);
fclose(fin);

% 라플라시안 마스크
H = [0 -1 0; 0 2 0;0 -1 0];
V = [0 0 0; -1 2 -1; 0 0 0];
D135 = [-1 0 0; 0 2 0; 0 0 -1];
D45 = [0 0 -1; 0 2 0; -1 0 0];

% 픽셀 분류(블럭 1개에 픽셀 4개)
a = 1;
for i = 1:4:256
    for j = 1:4:256
        block = ori(i:i+3,j:j+3);
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
up=zeros(512, 512);
for i = 1:1:256
    for j = 1:1:256
        up(i*2,j*2) = ori(i,j); % integer-pel
    end
end

for k = 2:2:502
    for j = 2:2:502
        for i = 0:2:10 % 수평방향(half-pel)
            up(k+i,j+5) = ((11 * up(k + i,j)) - (43 * up(k + i,j + 2)) + (160 * up(k + i,j + 4))	+ (160 * up(k + i,j + 6)) - (43 * up(k + i,j + 8)) + (11 * up(k + i,j + 10))) / 256;
        end
        for i = 0:2:10 % 수직방향(half-pel)
            up(k+ 5,j + i) = ((11 * up(k,j + i)) - (43 * up(k + 2,j + i)) + (160 * up(k + 4,j + i)) + (160 * up(k + 6,j + i)) - (43 * up(k + 8,j + i)) + (11 * up(k + 10,j + i))) / 256;
        end
        up(k + 5,j + 5) = ((11 * up(k + 5,j)) - (43 * up(k + 5,j + 2)) + (160 * up(k + 5,j + 4)) + (160 * up(k + 5,j + 6)) - (43 * up(k + 5,j + 8)) + (11 * up(k + 5,j + 10))) / 256; % j
    end
end

% 보간되지 않은 외곽 영역 채우기 (zero padding)
for i = 2:2:512
    up(1,i) = ((160 * up(2,i)) - (43 * up(4,i)) + (11 * up(6,i))) / 256;
    up(3,i) = ((160 * up(2,i)) + (160 * up(4,i)) - (43 * up(6,i)) + (11 * up(8,i))) / 256;
    up(5,i) = ((-(43 * up(2,i))) + (160 * up(4,i)) + (160 * up(6,i)) - (43 * up(8,i)) + (11 * up(10,i))) / 256;
    up(509,i) = (-(43 * up(512,i)) + (160 * up(510,i)) + (160 * up(508,i)) - (43 * up(506,i)) + (11 * up(504,i))) / 256;
    up(511,i) = ((160 * up(512,i)) + (160 * up(510,i)) - (43 * up(508,i)) + (11 * up(506,i))) / 256;
    up(i,1) = ((160 * up(i,2)) - (43 * up(i,4)) + (11 * up(i,6))) / 256;
    up(i,3) = ((160 * up(i,2)) + (160 * up(i,4)) - (43 * up(i,6)) + (11 * up(i,8))) / 256;
    up(i,5) = ((-(43 * up(i,2))) + (160 * up(i,4)) + (160 * up(i,6)) - (43 * up(i,8)) + (11 * up(i,10))) / 256;
    up(i,509) = (-(43 * up(i,512)) + (160 * up(i,510)) + (160 * up(i,508)) - (43 * up(i,506)) + (11 * up(i,504))) / 256;
    up(i,511) = ((160 * up(i,512)) + (160 * up(i,510)) - (43 * up(i,508)) + (11 * up(i,506))) / 256;
end
for i = 3:2:512
    up(1,i) = (up(1,i - 1) + up(1,i + 1)) / 2;
    up(3,i) = (up(3,i - 1) + up(3,i + 1)) / 2;
    up(5,i) = (up(5,i - 1) + up(5,i + 1)) / 2;
    up(509,i) = (up(509,i - 1) + up(509,i + 1)) / 2;
    up(511,i) = (up(511,i - 1) + up(511,i + 1)) / 2;
    up(i,1) = (up(i - 1,1) + up(i + 1,1)) / 2;
    up(i,3) = (up(i - 1,3) + up(i + 1,3)) / 2;
    up(i,5) = (up(i - 1,5) + up(i + 1,5)) / 2;
    up(i,509) = (up(i - 1,509) + up(i + 1,509)) / 2;
    up(i,511) = (up(i - 1,511) + up(i + 1,511)) / 2;
end

fout=fopen('./6-tap_lena(512x512).raw', 'wb');
fwrite(fout, up);
fclose(fout);

