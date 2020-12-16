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
tempSum2 = zeros(10,1);
classMean = zeros(10,1,6);
for i = 1:1:6
    for j = 1:1:8
        repreVec(:,:,8*(i-1)+j) = transpose(eigenVectors) * tempVec(:,8*(i-1)+j);
        tempSum2 = tempSum2 + repreVec(:,:,8*(i-1)+j);
        classMean(:,:,i) = classMean(:,:,i) + repreVec(:,:,8*(i-1)+j);
    end
    classMean(:,:,i) = classMean(:,:,i) / 8;  % 각 클래스의 평균 벡터 구하기
end

% 전체 representative vector의 평균 벡터 구하기
m2 = tempSum2/48;

% Normalization
normalizedVec2 = zeros(10,1,48);
for i = 1:1:6
    for j = 1:1:8
        normalizedVec2(:,:,8*(i-1)+j) = repreVec(:,:,8*(i-1)+j) - m2;
    end
end

% 배열 형태 변경
tempVec2 = zeros(10*1,48);
for i = 1:1:48
    tempVec2(:,i) = reshape(normalizedVec2(:,:,i),[10*1 1]);
end

% Normalization (클래스내)
tempDevi = zeros(10,1,48);
tempVec3 = zeros(10*1,48);
for i = 1:1:6
    for j = 1:1:8
        tempDevi(:,:,8*(i-1)+j) = repreVec(:,:,8*(i-1)+j) - classMean(:,:,i);  
        tempVec3(:,8*(i-1)+j) = reshape(tempDevi(:,:,8*(i-1)+j),[10*1 1]);
    end
end
D_intra = tempVec3 * transpose(tempVec3);

% Normalization (클래스간)
tempDevi2 = zeros(10,1,6);
tempVec4 = zeros(10*1,6);
for i = 1:1:6
    tempDevi2(:,:,i) = classMean(:,:,i) - m2;
    tempVec4(:,i) = reshape(tempDevi2(:,:,i),[10*1 1]);
end
D_inter = tempVec4 * transpose(tempVec4);

% 공분산 행렬 구하기
convariance2 = pinv(D_intra) * D_inter;

% 공분산 행렬의 고유값과 대응하는 고유벡터를 계산
[eigenVectors2,eigenValues2] = eigs(convariance2,5);

% Representatiave vector들을 투영하여 representative vector2 구하기
repreVec2 = zeros(5,1,48);
for i = 1:1:48
    repreVec2(:,:,i) = transpose(eigenVectors2) * tempVec2(:,i);
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
normalizedVec3 = zeros(112,92,12);
for i = 1:1:12
    normalizedVec3(:,:,i) = trainingVec2(:,:,i) - m;
end

% 배열 형태 변경
tempVec5 = zeros(112*92,12);
for i = 1:1:12
    tempVec5(:,i) = reshape(normalizedVec3(:,:,i),[112*92 1]);
end

% 추출된 eigen matrix로 투영
projVec = zeros(10,1,12);
for i = 1:1:12
    projVec(:,:,i) = transpose(eigenVectors) * tempVec5(:,i);
end

% 1차 mapping된 vector에서 average vector 제거
normalizedVec4 = zeros(10,1,12);
for i = 1:1:12
    normalizedVec4(:,:,i) = projVec(:,:,i) - m2;
end

% 배열 형태 변경
tempVec6 = zeros(10*1,12);
for i = 1:1:12
    tempVec6(:,i) = reshape(normalizedVec4(:,:,i),[10*1 1]);
end

% 추출된 eigen matrix로 투영
projVec2 = zeros(5,1,12);
for i = 1:1:12
    projVec2(:,:,i) = transpose(eigenVectors2) * tempVec6(:,i);
end

% 유클리드 거리 계산
euclideanD = zeros(48,12);
for i = 1:1:12
    for j = 1:1:48
        tempSum3 = zeros;
        for k = 1:1:5
            tempSum3 = tempSum3 + (projVec2(k,1,i) - repreVec2(k,1,j)).^2;
        end
        euclideanD(j,i) =  tempSum3;
    end
end

% 분류
[M,idx] = min(euclideanD);
idx = idx - 1;
result = floor(idx / 8) + 1;

% 결과 출력
disp("테스트 영상 분류 결과:")
disp(result);
