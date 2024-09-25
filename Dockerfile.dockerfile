
    # 빌드 스테이지
    FROM openjdk:17-alpine AS build

    # 최신 패키지로 업데이트
    RUN apk update && apk upgrade --no-cache

    # 소스 복사
    WORKDIR /app
    COPY . .

    # 소스 빌드
    RUN javac Main.java

    # 최종 스테이지 - 슬림한 이미지를 사용하여 크기 최적화
    FROM openjdk:17-alpine

    WORKDIR /app

    # 빌드된 결과물만 복사
    COPY --from=build /app/Main.class /app/

    # 애플리케이션 실행
    CMD ["java", "Main"]
    