# .PHONY:all clean

ifeq ($(DEBUG), true)
# -g是生成调试信息。GNU调试起可以利用该信息
CC = g++ -g -std=c++11
VERSION = debug
else
CC = g++ -std=c++11
VERSION = release
endif

#CC = gcc

# $(wildcard *.c)表示扫描当前目录下所有.c文件
SRCS = $(wildcard *.cxx)

#OBJS = nginx.o ngx_conf.o 这么一个一个增加太麻烦
#下行换一种写法，把字符串中的.c换成.o
OBJS = $(SRCS:.cxx=.o)

# 把字符串中的.c替换成.d
DEPS = $(SRCS:.cxx=.d)

# 可以指定BIN文件的位置,可执行文件的位置
BIN := $(addprefix $(BUILD_ROOT)/,$(BIN))

# 定义存放obj文件的目录，目录统一到一个位置才方便后续链接，不然到各个子目录去不好链接
# 注意下边这个字符串，末尾不要有空格，不然会有语法错误
LINK_OBJ_DIR = $(BUILD_ROOT)/app/link_obj
DEP_DIR = $(BUILD_ROOT)/app/dep

# -p是递归创建目录，没有就创建，有就不需要了
$(shell mkdir -p $(LINK_OBJ_DIR))
$(shell mkdir -p $(DEP_DIR))

#我们要把目标文件生成到上述目标文件目录中去，利用函数addprefix增加一个前缀
#处理后形如 /home/ubuntu/study_cpp/mztkn_study_nginx/nginx/app/link_obj/ngx_signal2.o
# := 在解析阶段直接复制常量字符串【立即展开】，而 = 在运行阶段事迹使用变量时在求值【延迟展开】
OBJS := $(addprefix $(LINK_OBJ_DIR)/,$(OBJS))
DEPS := $(addprefix $(DEP_DIR)/, $(DEPS))

#找到目录中所有.o文件
LINK_OBJ = $(wildcard $(LINK_OBJ_DIR)/*.o)
#因为构建依赖关系时app目录下这个.o文件还没构建出来，所以LINK_OBJ时缺少这个.o的，我们要把这个.o文件加进来
LINK_OBJ += $(OBJS)

#--------------------------------------------------------------------------------------------------
#make找到第一个目标开始执行[每个目标[就是我们要生成的东西]],其实都是定义一种依赖关系，目标格式为
#目标：目标依赖【可以省略】
#	要执行的命令【可以省略】
#如下这行会是开始执行的入口，执行就找到依赖项$(BIN)去执行了，同时也依赖了$(DEPS)
all:$(DEPS) $(OBJS) $(BIN)

#这里诸多.d摁键包含进来，每个.d文件都记录着一个.o文件所依赖的哪些.c和.h文件
ifneq ("(wildcard $(DEPS)), "")  # 如果不为空
include $(DEPS)
endif

#--------------------------------------------------------------1begin--------------------------------
#$(BIN):$(OBJS)
$(BIN):$(LINK_OBJ)
	@echo "-----------------------build $(VERSION) mode-----------------------------------------!!!"

#一些变量 $@:目标，   $^:所有目标依赖
#gcc -o 是生成可执行文件
	$(CC) -o $@ $^

#-------------------------------------------------------------1end-----------------------------------


#-------------------------------------------------------------2begin----------------------------------
#%.o:%.c
$(LINK_OBJ_DIR)/%.o:%.cxx
# gcc -c是生成.o目标文件 -I可以指定头文件的路径
#如下不排除有其他字符串，所以从其中专门把.c过滤出来
#$(CC) -o $@ -c $^
	$(CC) -I$(INCLUDE_PATH) -o $@ -c $(filter %.cxx,$^)

#------------------------------------------------------------2end-------------------------------------



#------------------------------------------------------------3begin-----------------------------------
#我们现在希望修改一个.h文件时也希望能够让make自动编译我们的项目，所以我们需要指明让.o依赖于.h文件
#哪一个.o依赖于哪些.h文件，我们可以用"gcc -MM c程序文件名"来获得这些依赖信息并重定向保存到.d文件中
#.d 文件可能形如 nginx.o: nginx.c ngx_func.h
# gcc -I$(include_path) -MM $^
#%.d:%.c
#$@ 是目标
$(DEP_DIR)/%.d:%.cxx
#gcc -MM $^ > $@
#echo 中 -n 表示后续追加不换行
	echo -n $(LINK_OBJ_DIR)/ > $@
#	>> 表示追加
	gcc -I$(INCLUDE_PATH) -MM $^ >> $@

# 以上处理后 ， .d文件内容就丰富了
#-----------------------------------------------------------3end--------------------------------------






