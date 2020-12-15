clearvars; % 작업 공간 지우기

% Training vector들을 읽기
trainingVec = zeros(112,92,48);
tempSum = zeros(112,92);
for i = 1:1:6
    for j = 1:1:8
        tempPath = "./Training/set_"+i+"/"+j+".bmp";
        x = imread(tempPath);
        x2 = cast(x(:,:,1),'double');  % 변수를 다른 데이터형으로 변환
        trainingVec(:,:,8*(i-1)+j) = x2;
        tempSum = tempSum + x2;
    end
end

% Average vector 구하기
m = tempSum/48;

% Normalization
normalizedVec = zeros(112,92,48);
for i = 1:1:6
    for j = 1:1:8
        normalizedVec(:,:,8*(i-1)+j) = trainingVec(:,:,8*(i-1)+j) - m;
    end
end

% 배열 형태 변경
tempVec = zeros(112*92,48);
for i = 1:1:48
    tempVec(:,i) = reshape(normalizedVec(:,:,i),[112*92 1]);
end

% 공분산 행렬 구하기
convariance = tempVec * transpose(tempVec);

% 공분산 행렬의 고유값과 대응하는 고유벡터를 계산
[eigenVectors,eigenValues] = eigs(convariance,10);

% Training vector들을 투영하여 representative vector 구하기
repreVec = zeros(10,1,48);
for i = 1:1:48
    repreVec(:,:,i) = transpose(eigenVectors) * tempVec(:,i);
end

% Test vector들을 읽기
trainingVec2 = zeros(112,92,12);
for i = 1:1:12
    tempPath2 = "./Test/"+i+".bmp";
    y = imread(tempPath2);
    y2 = cast(y(:,:,1),'double');  % 변수를 다른 데이터형으로 변환
    trainingVec2(:,:,i) = y2;
end

% Test vector에서 average vector 제거
normalizedVec2 = zeros(112,92,12);
for i = 1:1:12
    normalizedVec2(:,:,i) = trainingVec2(:,:,i) - m;
end

% 배열 형태 변경
tempVec2 = zeros(112*92,12);
for i = 1:1:12
    tempVec2(:,i) = reshape(normalizedVec2(:,:,i),[112*92 1]);
end

% 추출된 eigen matrix로 투영
projVec = zeros(10,1,12);
for i = 1:1:12
    projVec(:,:,i) = transpose(eigenVectors) * tempVec2(:,i);
end

% 유클리드 거리 계산
euclideanD = zeros(48,12);
for i = 1:1:12
    for j = 1:1:48
        tempSum2 = zeros;
        for k = 1:1:10
            tempSum2 = tempSum2 + (projVec(k,1,i) - repreVec(k,1,j)).^2;
        end
        euclideanD(j,i) =  tempSum2;
    end
end

% 분류
[M,idx] = min(euclideanD);
idx = idx - 1;
result = floor(idx / 8) + 1;

% 결과 출력
disp("테스트 영상 분류 결과:")
disp(result);
