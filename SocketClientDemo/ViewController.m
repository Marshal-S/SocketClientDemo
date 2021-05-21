//
//  ViewController.m
//  SocketClientDemo
//
//  Created by Marshal on 2021/5/19.
//  测试案例针对ipv4,对于ipv6的支持可以搜索，或者参考GCDAsyncSocket

#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

//htons : 将一个无符号短整型的主机数值转换为网络字节顺序，不同cpu 是不同的顺序 (big-endian大尾顺序 , little-endian小尾顺序)
#define SocketPort htons(8040)
//inet_addr是一个计算机函数，功能是将一个点分十进制的IPv4地址转换成一个长整数型数
#define SocketIP   inet_addr("172.26.105.76")

@interface ViewController ()

@property (nonatomic, assign) int clientId;
@property (weak, nonatomic) IBOutlet UITextField *tfMessage;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initClientSocket];
}

- (void)initClientSocket {
    /**
     1: 创建socket
     参数
     domain：协议域，又称协议族（family）。常用的协议族有AF_INET、AF_INET6、AF_LOCAL（或称AF_UNIX，Unix域Socket）、AF_ROUTE等。协议族决定了socket的地址类型，在通信中必须采用对应的地址，如AF_INET决定了要用ipv4地址（32位的）与端口号（16位的）的组合、AF_UNIX决定了要用一个绝对路径名作为地址。
     type：指定Socket类型。常用的socket类型有SOCK_STREAM、SOCK_DGRAM、SOCK_RAW、SOCK_PACKET、SOCK_SEQPACKET等。流式Socket（SOCK_STREAM）是一种面向连接的Socket，针对于面向连接的TCP服务应用。数据报式Socket（SOCK_DGRAM）是一种无连接的Socket，对应于无连接的UDP服务应用。
     protocol：指定协议。常用协议有IPPROTO_TCP、IPPROTO_UDP、IPPROTO_STCP、IPPROTO_TIPC等，分别对应TCP传输协议、UDP传输协议、STCP传输协议、TIPC传输协议。
     注意：1.type和protocol不可以随意组合，如SOCK_STREAM不可以跟IPPROTO_UDP组合。当第三个参数为0时，会自动选择第二个参数类型对应的默认协议。
     返回值:
     如果调用成功就返回新创建的套接字的描述符，如果失败就返回INVALID_SOCKET（Linux下失败返回-1）
     */
    self.clientId = socket(AF_INET, SOCK_STREAM, 0);
    if (self.clientId == -1) {
        NSLog(@"创建socket失败");
        return;
    }
    
    /**
     __uint8_t    sin_len;          假如没有这个成员，其所占的一个字节被并入到sin_family成员中
     sa_family_t    sin_family;     一般来说AF_INET（地址族）PF_INET（协议族）
     in_port_t    sin_port;         // 端口
     struct    in_addr sin_addr;    // ip
     char        sin_zero[8];       没有实际意义,只是为了　跟SOCKADDR结构在内存中对齐
     */
    
    struct sockaddr_in socketAddr;
    socketAddr.sin_family = AF_INET;
    socketAddr.sin_port = SocketPort;
    socketAddr.sin_addr.s_addr = SocketIP;
    
    //
    /**
     参数
     参数一：套接字描述符
     参数二：指向数据结构sockaddr的指针，其中包括目的端口和IP地址
     参数三：参数二sockaddr的长度，可以通过sizeof（struct sockaddr）获得
     返回值
     成功则返回0，失败返回非0，错误码GetLastError()。
     */
    int result = connect(self.clientId, (const struct sockaddr *)&socketAddr, sizeof(socketAddr));
    
    if (result != 0) {
        NSLog(@"连接失败");
        return;
    }else {
        NSLog(@"连接成功");
    }
    
    //接收消息
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self reciveMessage];
    });
    
    //根据id断开客户端的连接
//    close(self.clientId);
}

//开始进入接收消息状态
- (void)reciveMessage {
    // 4. 接收数据
    /**
     参数
     1> 客户端socket
     2> 接收内容缓冲区地址
     3> 接收内容缓存区长度
     4> 接收方式，0表示阻塞，必须等待服务器返回数据
     
     返回值
     如果成功，则返回读入的字节数，失败则返回SOCKET_ERROR
     */
    //可以开启一个子线程，开启runloop在里面定时接收消息
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.2 repeats:YES block:^(NSTimer * _Nonnull timer) {
        uint8_t buffer[1024];
        ssize_t recvLen = recv(self.clientId, buffer, sizeof(buffer), 0);
        if (recvLen == 0) {
            NSLog(@"接收到了空白消息");
            return;
        }
        NSData *recvData = [NSData dataWithBytes:buffer length:recvLen];
        NSString *recvString = [[NSString alloc] initWithData:recvData encoding:NSUTF8StringEncoding];
        
        NSLog(@"接收到消息:%@", recvString);
    }];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    [[NSRunLoop currentRunLoop] run];
 }

//向服务端发送消息
- (IBAction)sendMessage:(id)sender {
    const char *msg = self.tfMessage.text.UTF8String;
    ssize_t sendLen = send(self.clientId,msg, strlen(msg), 0);
    _tfMessage.text = @"";
    NSLog(@"发送成功了%ld字节", sendLen);
}

@end
