--- 模块功能：文件操作功能测试.
-- @author openLuat
-- @module fs.testFs
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.27

module(...,package.seeall)

local USER_DIR1,USER_DIR11 = "/dir1","/dir11"
local USER_DIR2,USER_DIR21,USER_DIR211 = "/dir2","/dir21","/dir211"
local USER_DIR3 = "/dir3"
local fileval

--[[该demo提供四种接口，第一种readfile(filename)读文件，第二种writevala(filename,value)，写文件内容，附加模式，
第三种function writevalw(filename,value)，写文件内容，覆盖模式，第四种deletefile(filename)，删除文件。--]]

--[[
    函数名：readfile(filename)
    功能：打开所输入文件名的文件，并输出储存在里面额内容
    参数：文件名
    返回值：无                     ]]
local function readfile(filename)--打开指定文件并输出内容
    
    local filehandle=io.open(filename,"r")--第一个参数是文件名，第二个是打开方式，'r'读模式,'w'写模式，对数据进行覆盖,'a'附加模式,'b'加在模式后面表示以二进制形式打开
    if filehandle then          --判断文件是否存在
        fileval=filehandle:read("*all")--读出文件内容
      if  fileval  then
           print(fileval)  --如果文件存在，打印文件内容
           readstr = fileval
           filehandle:close()--关闭文件
      else 
           print("The file is empty")--文件不存在
      end
    else 
        print("文件不存在或文件输入格式不正确") --打开失败  
    end 
    return fileval
end



--[[
    函数名： writevala(filename,value)
    功能：向输入的文件中添加内容，内容附加在原文件内容之后
    参数：第一个文件名，第二个需要添加的内容
    返回值：无                         --]]
local function writevala(filename,value)--在指定文件中添加内容,函数名最后一位就是打开的模式
    local filehandle = io.open(filename,"a+")--第一个参数是文件名，后一个是打开模式'r'读模式,'w'写模式，对数据进行覆盖,'a'附加模式,'b'加在模式后面表示以二进制形式打开
    if filehandle then
        filehandle:write(value)--写入要写入的内容
        filehandle:close()
    else
        print("文件不存在或文件输入格式不正确") --打开失败  
    end
end



--[[
    函数名：writevalw(filename,value)
    功能：向输入文件中添加内容，新添加的内容会覆盖掉原文件中的内容
    参数：同上
    返回值：无                 --]]
local function writevalw(filename,value)--在指定文件中添加内容
    local filehandle = io.open(filename,"w")--第一个参数是文件名，后一个是打开模式'r'读模式,'w'写模式，对数据进行覆盖,'a'附加模式,'b'加在模式后面表示以二进制形式打开
    if filehandle then
        filehandle:write(value)--写入要写入的内容
        filehandle:close()
    else
        print("文件不存在或文件输入格式不正确") --打开失败  
    end
end


--[[函数名：deletefile(filename)
    功能：删除指定文件中的所有内容
    参数：文件名
    返回值：无             --]]
local function deletefile(filename)--删除指定文件夹中的所有内容
    local filehandle = io.open(filename,"w")
    if filehandle then
        filehandle:write()--写入空的内容
        print("successfully delete")
        filehandle:close()
    else
        print("文件不存在或文件输入格式不正确") --打开失败  
    end
end

--打印文件系统的剩余空间
print("get_fs_free_size: "..rtos.get_fs_free_size().." Bytes")
--成功创建一个目录(目录已存在，也返回true表示创建成功)

local function dir1test()
    if rtos.make_dir(USER_DIR1) then
        if rtos.make_dir(USER_DIR11) then
            writevalw(USER_DIR11.."/file11.txt","file11 test")
            readfile(USER_DIR11.."/file11.txt")
            
            writevalw(USER_DIR11.."/file12.txt","file12 test")
            readfile(USER_DIR11.."/file12.txt")        
        end
    end
end

local function dir2test()
    if rtos.make_dir(USER_DIR2) then
        if rtos.make_dir(USER_DIR21) then
            rtos.make_dir(USER_DIR211)
            writevalw(USER_DIR21.."/file21.txt","file21 test")
            readfile(USER_DIR21.."/file21.txt")
            
            writevalw(USER_DIR21.."/file3.txt","file3 test")
            readfile(USER_DIR21.."/file3.txt")        
        end
    end
end

local function file1test()
    writevalw("/file1.txt","file1 test")
    readfile("/file1.txt")    
end

local function file3test()
    readfile("/file3.txt")
    writevala("/file3.txt","file3 test")
    readfile("/file3.txt")
    writevalw("/file3.txt","file3 test2")
    local str = readfile("/file3.txt")
    if str == "file3 test2" then
        print("file3 test success")
        testUart.write("file3 test success")
    else
        print("file3 test fail")
        testUart.write("file3 test fail")
    end
end

local function file4test()
    writevala("/file4.txt","file4 test")
    readfile("/file4.txt")
    writevalw("/file4.txt","file4 test2")
    local str = readfile("/file4.txt")
    if str == "file4 test2" then
        print("file4 test success")
        testUart.write("file4 test success")
    else
        print("file4 test fail")
        testUart.write("file4 test fail")
    end   
end

local function dir3test()
    if rtos.make_dir(USER_DIR3) then
        print("MAKE DIR3 SUCC")
    else
        print("MAKE DIR3 FAIL")        
    end
end

local function test()
    local str1 = readfile(USER_DIR11.."/file11.txt")
    if str1 == "file11 test" then
        print("readfile file11 test success")
        testUart.write("readfile file11 test success")
    else
        print("readfile file11 test fail")
        testUart.write("readfile file11 test fail")        
    end
    
    local str2 = readfile(USER_DIR11.."/file12.txt")
    if str2 == "file12 test" then
        print("readfile file12 test success")
        testUart.write("readfile file12 test success")        
    else
        print("readfile file12 test fail")
        testUart.write("readfile file12 test fail")        
    end
    
    local str3 = readfile(USER_DIR21.."/file21.txt")
    if str3 == "file21 test" then
        print("readfile file21 test success")
        testUart.write("readfile file21 test success")        
    else
        print("readfile file21 test fail")
        testUart.write("readfile file21 test fail")         
    end
    
    local str4 = readfile(USER_DIR21.."/file3.txt")
    if str4 == "file3 test" then
        print("readfile DIR21 file3 test success")
        testUart.write("readfile DIR21 file3 test success")         
    else
        print("readfile DIR21 file3 test fail")
        testUart.write("readfile DIR21 file3 test fail")        
    end  
    
    local str5 =readfile("/file1.txt")
    if str5 == "file1 test" then
        print("readfile file1 test success")
        testUart.write("readfile file1 test success")        
    else
        print("readfile file1 test fail")
        testUart.write("readfile file1 test fail")        
    end     
    file3test()
    file4test()
end

--file1test()
--dir1test()
--dir2test()
--dir3test()

sys.timerLoopStart(test,1000)
