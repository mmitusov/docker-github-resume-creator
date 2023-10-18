
# In order to build the container image, you’ll need to use a Dockerfile. 
# A Dockerfile is simply a text-based file with no file extension. A Dockerfile contains a script of instructions that Docker uses to create a container image.
# Здесь мы будем создавать новый image (образ) который в последствии запустим в контейнере (из него создадим контейнер)

# Обновленнная версия с кешированием:
# Зачем нам нужно 2 вида COPY и работа с ENV - описано в README.md
FROM node:alpine
WORKDIR /app
COPY package.json /app
RUN npm install
COPY . .
CMD npm start
# OR - CMD [ "npm", "start" ]
ENV PORT 2000
EXPOSE $PORT

# Если мы предваритеьлно не предустанавливали image среду в котором работает приложение, то докер автоматом попытается найти его у себя ищя то что мы указали в FROM
# Говорим что наш образ мы будем базировать на основе образа node
# Официальный перечень среды базовых образов можно найти на официальном сайте Докер Хабе
# Также, при желании, можно указать от конкретно какого базоваго образа мы хотим наследовать нашу среду, например: FROM node:alpine
# alpine - это очень легковестная линукс дистро, на базе которой будет запускаться наш node. Можно использовать для повышения производительности и сохранения памяти
# -----> FROM node 

# Due to changes in NodeJS if we don't spesify WORKDIR starting from version 15, our 'docker build' command will result in err
# WORKDIR указывает где будет создана директория для докер образа, в которую мы потом скопируем наш проект. Установим '/app' как нашу рабочею директорию
# Благодаря WORKDIR докер отмечает для себя стартовую директорию где находиться проект, чтобы в последующих инструкциях нам не нужно было явно указывать ее название каждый раз
# Например, вместо "COPY . /app", теперь можно писать "COPY . ."
# -----> WORKDIR /app

# image это некая файловая система в которой еще ничего нет и нам нужно указать какие именно файлы мы хотим переместить внутри него и запускать их там
# И тем самым мы говорим какие файлы мы там фиксируем (однажды создав образ мы его больше не сможем поменять)
# Настроим параметры нашего образа чтобы создать от него конейнер
# COPY копирует файлы из нашего приложения в image.  
# Первый параметр - от куда и что мы хотим копировать. Если ставим точку - то все сущности в корне проекта (из текущей директории где мы находимся). Начальной точкой директории считается то место где лежит Dockerfile
# Второй параметр - куда в image мы хотим поместить эти файлы. Можно положить все в корень (поставить точку), но обычно создается какая-то специальная папка, которая будет служить корневой для всего приложения (e.g. /app)
# То есть, у того образа куда мы копируем проект, есть своя файловая система, и внутри этой системы мы создаем новую директорию "/app", и переносим туда свой проект
# Либо же мы можем заранее задать второй параметр при помощи команды WORKDIR (рабочая директория приложения/контекст где мы будем запускать приложение)
# И уже в WORKDIR укажем местоположение где лежат все наши файлы
# И если мы используем команду WORKDIR, то в COPY вторым параметром можно просто оставить точку
# -----> COPY . .

# Далее для того чтобы впоследствии запустить наше приложение, нам предварительно нужно скачать все необходимые для его работы зависимости
# -----> RUN npm install

# И далее чтобы запустить приложение нам нужно указать какой именно командой наше приложение запускается
# -----> CMD npm start / CMD [ "npm", "start" ]

# P.S. Команда RUN запускается каждый раз когда мы строим наш образ, а CMD только тогда, когда мы запускаем наш уже готовый образ

# Команда которая говорит на каком порте будет запущенно наше приложение. P.S. Команда не обязательна, но считается как best practice
# -----> EXPOSE 3000

# И после настройки параметров нашего образа в консоли запускаем: docker build <APP_PATH> (для локальной дериктории - "docker build .") - чтобы запустить билд приложения
# !!!Перед началом билда - if you are on Mac, make sure docker desktop is running
# После билда мы можем посмотреть список наших готовых образов при помощи команды: docker images или docker image ls (разницы нет). В списке мы увидем как имя нашего билда так и его уникальный IMAGE ID
# Далее запустим наш контейнер созданный на образе ранее сконфигурированного image, при помощи команды: docker run <IMAGE_ID>
# При помощи команды 'docker ps' мы можем посмотреть список запущенных нами контейнеров
# Чтобы остановить любой из запущенных контейнеров, воспользуемся командой: docker stop <CONTAINER_ID_or_Name>
# После чего мы увидем что наш контейнер пропал со списка запущенных ('docker ps')
# Но при он будет отображаться просто в списке всех контейнеров. Отобразить список всех контейнеров можно при помощи команды: docker ps -a
# И при необходимости мы можем заново запусакть контейнеры из этого списка, при помощи конанды docker start <CONTAINER_ID_or_Name>
# Всесто ID-шников, для start/stop команд, можно также использовать уникальные именна которые автоматически присвоемнны докером каждому новому созданному контейнеру

# Но в чем же разница между 'docker run <IMAGE_ID>' vs 'docker start <CONTAINER_ID_or_Name>'?
# run - работает с образами, а start - с контейнерами

# P.S.S. Каждый раз когда мы запускаем команду docker run <IMAGE_ID> - мы всегда создаем НОВЫЙ контейнер на основе нашего image. И из-за этого эти контейнеры могу начать копиться на нашей машине в больших количествах
# А 'docker start <CONTAINER_ID_or_Name>' - просто запускает уже ранее созданный контейнер
# Поэтому преодически желательно не нужные контрейнеры удалять
# Чтобы удалить все КОНТЕЙНЕРЫ за один раз (кроме уже активных/запущенных) - docker container prune
# Чтобы удалить какой то конкретный КОНТЕЙНЕР (один или больше) - docker rm <CONTAINER_ID_or_Name1> <CONTAINER_ID_or_Name2> ...
# Чтобы удалить все ОБРАЗЫ за один раз (кроме уже активных/запущенных) - docker image prune
# Чтобы удалить какой то конкретный ОБРАЗ (один или больше) - docker rmi <IMAGE_ID1> <IMAGE_ID2> ...

# Но в примере выше хоть мы и запустили контейнер, но мы пока еще не можем воспользоваться работающим внутри приложением и открыть его например в http://localhost:3000
# Для этого в 'docker run <IMAGE_ID>' нужно добавить еще пару параметров. Первый '-p' (порт) и после него указываем какой именно набор портов, например '3000:3100, 80:3000 и т.д.'
# docker run -p 3000:3100 <IMAGE_ID>
# Первый порт говорит нам какой локальный порт использовать на нашей машине, чтобы запустить контейнер в браузере. 
# А второй - какой порт из контейнера мы хотим замапить на наш локальный (порт для контейнера)
# То есть 'порт_который_хотим_использовать_локально : порт_внутри_контейнера (e.g. EXPOSE 3100)'
# You use the -d flag to run the new container in “detached” mode (in the background). You also use the -p flag to create a mapping between the host’s port 3000 to the container’s port 3000. 
# Without the port mapping, you wouldn’t be able to access the application.
# Вуаля! Теперь мы можем запускать контейрер, открывать его на локал хосте и пользоваться нашим приложением

# Однако каждый раз когда мы запускаем docker run -p 3000:3100 <IMAGE_ID>, мы можем заметить, что мы погружаемся в текущею консоль и больше ничего в ней не можем писать пока не завершим процесс
# Чтобы иметь возможность продолжать работу с текущей консолью, добавим еще одним параметром '-d': docker run -d -p 3000:3000 <IMAGE_ID>
# Так просто удобнее, чтобы не дополнительно не запускать вторую консоль
