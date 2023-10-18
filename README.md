Базовая логика работы с Dockerfile и Докером вцелом, описана в самом Dockerfile файле.

# Dockerfile vs docker-compose.yaml file
The contents of a Dockerfile describe how to create and build a Docker image, while docker-compose is a command that runs Docker containers based on settings described in a docker-compose.yaml file.

# Кеширование
Напомню, что однажды создав image (образ) мы его больше не можем его менять или обновлять. То есть мы изолируем наш текущий код от любого внешнего воздействия (фиксируем состояние кода), чтобы внешняя среда уже никак не могла повлиять на его работу. И кстати именно поэтому любые продукты работы приложения (если такие имеются), мы не сможем увидеть в папке нашего оригинального приложения. Так как любые продукты работы откладываются теперь в запущенном контейнере, а не в нашем исходном коде/приложении. Наше оригинальное приложение никак не меняется. Потому что наше оригинально приложение и image - это две разные вещи.

Поэтому возникает вопрос. Что делать если я внес изменения в свой проект и теперь хочу, чтобы этот функционал теперь появился и в image, и в последующе запущенном контейнере?

Так как любой образ иммутабельный, и мы никак не можем обновить уже созданный/существующий образ, то под новые изменения, нам остается только создать новый образ - `docker build <APP_PATH>`. И при этом каждый из images будет представлять какую-то конкретную версию приложения "застывшею во времени".

Но, чтобы боротся с таким базовым поведением из коробки, у Докера есть хорошая система кеширования, которая может помочь упростить нам процесс создания нового образа и сделать его менее ресурсозатратным и более быстрым для системы. Мы просто немного обновим логику в Dockerfile и перед `RUN npm install` добавим поле - `COPY package.json /app`:
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

# Полезные команды
Подключиться к уже запущенному контейнеру: `docker attach <CONTAINER_ID_or_Name>`
Посмотреть, что происходило в контейнере (какие логи выводились в консоль): `docker logs <CONTAINER_ID_or_Name>`

# Параметры которые мы можем добавлять при запуске нового контейнера
`docker run -d -p 3000:3000 --rm --name container_name <IMAGE_ID>`
'--name container_name' - имя которое мы можем сами задать контейнеру. И теперь нам не нужно помнить ID контейнера для его запуска/остановки, мы можем запустить по нашему созданому имени
'--rm' - этот параметр автоматически удаляет контейнер сразу как только мы останавливаем его работу. Помогает нам не откладывать в нашей памяти куча не нужных контейнеров при каждом новом запуске образа

# Повышаем удобство работы
Так как при каждом запуске образа каждый раз обращаться к нему по его ID-шнику не удобно, то для каждого нового обаза, в момент его создания, мы можем задавать ему свое имя и/или специальные теги при его зборке
'-t image_name' - имя которое мы даем образу при его создании
`docker build -t image_name .`
После чего мы теперь можем создавать контейнеры не по ID-шнику нашего образа, а по ранее присвоеному ему имени
`docker run -d -p 3000:3000 --rm --name container-name image_name`: создаем и запускаем контейнер в “detached” режиме, на порте 3000, под именем container-name, на онове образа image_name, который самоудаляется после завершения процесса (--rm)

Также для наших image можно задавать Теги (версии) при их создании. То есть мы можем создать много образов с одинаковым именем но дать всем им разные теги. В итоге это можно использовать чтобы для разных версий одного и того же приложения не придумавать каждый раз новое имя, а просто давать этому приложению разные Теги, которые будут служить как бы именем его версии.
Для этого, при создании образа, когда мы задаем ему имя - просто добавим к его имени еще и название его тега(версии) ':version_tag'
`docker build -t image_name:version_tag .`
И тогда при запуске контейнера мы можем указывать какую версию приложения мы хотим запустить исходя из его тега:
`docker run -d -p 3000:3000 --rm --name container-name image_name:version_tag`
Но если мы самостоятельно не задаем тег при наименовании образа, то докер создаст его автоматически за нас. И зачастую он присваивает имя тега - 'latest'

`docker image inspect <IMAGE_ID_or_Name>` - детальная информация об образе

# Как делиться образами и где их хранить
DockerHub - специально созданая плаформа для хранения и распространения Docker Images. В аккаунт можно залогиниться как из веб страницы, так и примиком из терминала, при помощи команды - docker login.

Далее чтобы залить образ, нужно:
1. При помощи команды docker images проверить id или имя (REPOSITORY) того образа, что мы хотим загрузить. Если при создании образа мы не давали ему имя - то тогда юзам его id
2. При помощи команды docker tag - переименовуем образ чтобы его имя (REPOSITORY) включала сначало ник юзара а затем уже имя образа: <User_DockerHub_Name>/<IMAGE_ID_or_Name>
4. Используя команду 'doker push <User_DockerHub_Name>/<IMAGE_ID_or_Name>' заливаем образ в DockerHub
5. И при помощи 'doker pull <User_DockerHub_Name>/<IMAGE_ID_or_Name>' - мы также можем загружать свои или чужие образы на нашу машину

# .dockerignore
Не забываем прописывать все то, что нам не нужно тянуть с собой (в DockerHub) при заливе нашеого образа на DockerHub. Например: node_modules, .git etc. Также можно и добавить Dockerfile файл. Так как он хоть и нужен для постоения образа, но мы то заливаем уже построенный/готовый образ, и повторной необходимости в том чтобы его строить у нас нет.

# .env переменные
В Dockerfile мы также можем задавать системные переменные для нашего образа (IMAGE). Например, то на каком порте должно работать наше приложение.
Это, например, может быть полезно на бекенде. Когда мы задаем `const port = process.env.PORT ?? 3000`. В данном случае если мы не зададим ENV переменные в Dockerfile, у нас всегда будет отрабатывать 3000 вместо process.env.PORT. Как раз таки .env.PORT мы и хотим задать.
Есть 2 способа, чтобы задавать ENV переменные.

Способ 1:
Чтобы задать ENV переменную, нужно воспользоваться следующим синтаксисом:
ENV PORT 3000
Где PORT - название ENV переменной, а 3000 - это ее значение. ---> ENV <variable> <value>
Но если мы задаем в ENV наш дефолтный порт, то в EXPOSE 3000 - его можно уже не дублировать. Хотя при желании можно и оставить: ENV PORT 3000, EXPOSE 3000. Но это не лучшая практика. Поэтому можем обновить наш Dockerfile следующим образом:
До - `EXPOSE 3000`
После -
```
ENV PORT 2000
EXPOSE $PORT
```
Знак '$' - это специальный синтаксис по обращанию к ранее заданым переменным.
И запустим наш контейнер - `docker run -d -p 3000:2000 --rm --name container_name <IMAGE_ID>`

Способ 2:
Также можно задавть ряд переменных прямиком внутри docker команды. Где мы можем задавать одну или больше перменных в виде `-e VARIABLE=VALUE`:
`docker run -d -p 3000:80 -e PORT=80 -e VARIABLE=VALUE --rm --name container_name <IMAGE_ID>`
При чем порт контейнера и переменной должны совпадать. :80 = PORT=80 = EXPOSE $PORT

Способ 3:
Можно вообще создать отдельный файл со всеми переменными. Например, создадим папку config с файлом .env внутри. В нем, например укажем PORT=2020. И теперь чтобы подтягивать из него информацию при билде образа, мы можем в docker команде, дополнительно воспользоватся следующей командой: --env-file ./config/.env. В итоге финальный вид команды должен будет выглядеть следующим образом:
`docker run -d -p 3000:2020 --env-file ./config/.env --rm --name container_name <IMAGE_ID>`

# Кастомные шорткаты для консольных команд
Вопревых, у нас должно быть установленно расширение "make" на компьтере. Далее, в корне приложения мы можем создать следующий файл: Makefile. И внутри этого файла задавать разные шорткаты стандартным командам. Например:
```
run: 
    docker run -d -p 3000:2000 --rm --name container_name <IMAGE_ID>
```
Далее, убедившись что у нас стоит расширение "make" на компьютере, вызываем этот шорткат как:
`make run`

# Docker volumes
volumes - используются для хранения данных. Но чтобы понятно объяснить принцип работы volumes в докере, сперва вспомним принцип работы самого докера.
Итак, мы знаем, что каждый отдельный докер контейнер созданный из образа имеет свою внутрению файловую систему и свою собственную память. И если мы не удаляем контейнер после его отключения, то вся наработаная им ранее информация никуда не исчезает после его отключения. при повторном запуске контейнера она будет вновь доступна. Не важно, это может быть и картинки и БД и документы и т.д.
Но что если мы удалим наш контейнер? Или мы например хотим создать новый контейнер с обновленным кодом из обновленного образа. Но создавая новый контейнер мы получается теряем всю ранее наработаную его предшествиником информацию (БД, юзеров и т.д.)? Или мы просто любим задавать автоматическое удалание контейнера как только мы его останавливаем. Опять тот же результат - весь прогресс и все данные обнуляются. Как мы видим, это крайне не удобно.
И как решением этой проблемы, тут мы как раз можем воспользоваться концепцией - volumes. volumes - это некая внешняя память, которая существует за перделами самого контейнера. При чем один volume, может делиться памятью/данными сразу с несколькими контейнерами. То есть список volumes существует отдельно от списка контейнеров.

Первый способ сознания volumes:
Сперва стоит заметить то, что чтобы volume хранил в себе информацию, у него должно быть заданое нами имя. По наименованию volumes деляться на 2 типа: именованные (мы задаем имя вручную) и анонимные (имя создается автоматически в виде криптографического колюча). Анонимный volume удаляется сразу как удаляется сам контейнер. И чтобы сохранять volumes после удаления контейнера, нам как раз таки и нужно задавать имя вручную. Через команду имя задается следующим образом:
`-v <our_volume_name>:/app/<file_with_data>`
-v - указывает на то, что мы работаем с volumes;
<our_volume_name>: - создаем кастомное имя для нашего volume
/app/<file_with_data> - указываем путь, где к файлам инфо о которых мы хотим сохранить, даже после удаления контейнера.
`docker run -d -p 3000:3000 -v <our_volume_name>:/app/<file_with_data> --rm --name container_name <IMAGE_ID>`

Но перед тем как запускать билд контейнера, нам также необходимо добавить следующий параметр в наш Dockerfile:
`VOLUME [ "/app/<file_with_data>" ]`

И теперь после билда контейнера и/или его удаления, мы можем проверить перечень созданных нами volumes при помощи следующей команды:
`docker volume ls`

Как мы можем после этого заметить, у нас теперь имеется volume который хранит данные из контейнера, даже после его удаления. Так что после повторного билда контейнера, информация о нем не обнулится/потеряется.

`docker volume inspect <our_volume_name>` - чтобы посмотреть инфо справку о volume
`docker volume create <our_volume_name>` - вручную создаем имя volume, вместо того чтобы использовать команду `-v <our_volume_name>:/app/<file_with_data>` при создании контейнера. Эти команды равносильны.

Также volumes могут помочь решить ту ситуацию, когда при изменении кода, нам нужно каждый раз создавать новый образ и от него запускать новый контейнер. Так как работающий контейнер теперь берет информацию из созданного нами volume, который находиться за его пределами. И теперь инфо не замкнута внутри самого контейнера и не изолированная от всего мира. То теперь мы можем манипулировать контейнером, при помощи внешне созданного volume, так как контейнер теперь берет теперь инфу из вне (из volume), а не сам из себя. В таком случае нам не нужно пересобирать образ чтобы увидеть изменения, достаточно обновить volume и контейнер сможет просто подтянуть и отобразить новое состояние. P.S. СКОРЕЙ ВСЕГО описание выше не совсем корректно, но общий смысл передает.

# Деплой Docker