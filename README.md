
Напомню, что однажды создав image (образ) мы его больше не можем его менять или обновлять. То есть мы изолируем наш текущий код от любого внешнего воздействия (фиксируем состояние кода), чтобы внешняя среда уже никак не могла повлиять на его работу. И кстати именно поэтому любые продукты работы приложения (если такие имеются), мы не сможем увидеть в папке нашего оригинального приложения. Так как любые продукты работы откладываются теперь в запущенном контейнере, а не в нашем исходном коде/приложении. Наше оригинальное приложение никак не меняется. Потому что наше оригинально приложение и image - это две разные вещи.

Поэтому возникает вопрос. Что делать если я внес изменения в свой проект и теперь хочу, чтобы этот функционал теперь появился и в image, и в последующе запущенном контейнере?

Так как любой образ иммутабельный, и мы никак не можем обновить уже созданный/существующий образ, то под новые изменения, нам остается только создать новый образ - docker build <APP_PATH>. И при этом каждый из images будет представлять какую-то конкретную версию приложения "застывшею во времени".

Но, чтобы боротся с таким базовым поведением из коробки, у Докера есть хорошая система кеширования, которая может помочь упростить нам процесс создания нового образа и сделать его менее ресурсозатратным и более быстрым для системы. Мы просто немного обновим логику в Dockerfile и перед RUN npm install добавим поле - COPY package.json /app:
```
FROM node 
WORKDIR /app
COPY package.json /app (или 'package.json .' - это одно и тоже самое)
RUN npm install
COPY . .
CMD [ "npm", "start" ]
EXPOSE 3000
```
Теперь при новой сборке образа, мы пердварительно будем проверять есть ли у нас какие либо изменения в package.json, то есть - есть ли у нас изменения в наших модулях. И если их нет, то мы не будем по новой каждый раз тратить ресурсы на повторную установку необходимых нам для работы модулей, а просто будем брать их из кеша, что значительно ускорит создание нового образа.