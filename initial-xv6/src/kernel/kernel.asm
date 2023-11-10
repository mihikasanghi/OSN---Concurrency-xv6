
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a4010113          	addi	sp,sp,-1472 # 80008a40 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8ae70713          	addi	a4,a4,-1874 # 80008900 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	00c78793          	addi	a5,a5,12 # 80006070 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc08f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	4be080e7          	jalr	1214(ra) # 800025ea <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8b650513          	addi	a0,a0,-1866 # 80010a40 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8a648493          	addi	s1,s1,-1882 # 80010a40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	93690913          	addi	s2,s2,-1738 # 80010ad8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	26c080e7          	jalr	620(ra) # 80002434 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	faa080e7          	jalr	-86(ra) # 80002180 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	382080e7          	jalr	898(ra) # 80002594 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	81a50513          	addi	a0,a0,-2022 # 80010a40 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	80450513          	addi	a0,a0,-2044 # 80010a40 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72323          	sw	a5,-1946(a4) # 80010ad8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	77450513          	addi	a0,a0,1908 # 80010a40 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	34e080e7          	jalr	846(ra) # 80002640 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	74650513          	addi	a0,a0,1862 # 80010a40 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	72270713          	addi	a4,a4,1826 # 80010a40 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	6f878793          	addi	a5,a5,1784 # 80010a40 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7627a783          	lw	a5,1890(a5) # 80010ad8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6b670713          	addi	a4,a4,1718 # 80010a40 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6a648493          	addi	s1,s1,1702 # 80010a40 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	66a70713          	addi	a4,a4,1642 # 80010a40 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6ef72a23          	sw	a5,1780(a4) # 80010ae0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	62e78793          	addi	a5,a5,1582 # 80010a40 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7a323          	sw	a2,1702(a5) # 80010adc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	69a50513          	addi	a0,a0,1690 # 80010ad8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d9e080e7          	jalr	-610(ra) # 800021e4 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5e050513          	addi	a0,a0,1504 # 80010a40 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	16078793          	addi	a5,a5,352 # 800215d8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5a07ab23          	sw	zero,1462(a5) # 80010b00 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	d3450513          	addi	a0,a0,-716 # 800082a0 <digits+0x260>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	34f72123          	sw	a5,834(a4) # 800088c0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	546dad83          	lw	s11,1350(s11) # 80010b00 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	4f050513          	addi	a0,a0,1264 # 80010ae8 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	39250513          	addi	a0,a0,914 # 80010ae8 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	37648493          	addi	s1,s1,886 # 80010ae8 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	33650513          	addi	a0,a0,822 # 80010b08 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0c27a783          	lw	a5,194(a5) # 800088c0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0927b783          	ld	a5,146(a5) # 800088c8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	09273703          	ld	a4,146(a4) # 800088d0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	2a8a0a13          	addi	s4,s4,680 # 80010b08 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	06048493          	addi	s1,s1,96 # 800088c8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	06098993          	addi	s3,s3,96 # 800088d0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	952080e7          	jalr	-1710(ra) # 800021e4 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	23a50513          	addi	a0,a0,570 # 80010b08 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	fe27a783          	lw	a5,-30(a5) # 800088c0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	fe873703          	ld	a4,-24(a4) # 800088d0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	fd87b783          	ld	a5,-40(a5) # 800088c8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	20c98993          	addi	s3,s3,524 # 80010b08 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fc448493          	addi	s1,s1,-60 # 800088c8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fc490913          	addi	s2,s2,-60 # 800088d0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	864080e7          	jalr	-1948(ra) # 80002180 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1d648493          	addi	s1,s1,470 # 80010b08 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	f8e7b523          	sd	a4,-118(a5) # 800088d0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	14c48493          	addi	s1,s1,332 # 80010b08 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00022797          	auipc	a5,0x22
    80000a02:	d7278793          	addi	a5,a5,-654 # 80022770 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	12290913          	addi	s2,s2,290 # 80010b40 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	08650513          	addi	a0,a0,134 # 80010b40 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	ca250513          	addi	a0,a0,-862 # 80022770 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	05048493          	addi	s1,s1,80 # 80010b40 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	03850513          	addi	a0,a0,56 # 80010b40 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	00c50513          	addi	a0,a0,12 # 80010b40 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a5070713          	addi	a4,a4,-1456 # 800088d8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	ad2080e7          	jalr	-1326(ra) # 80002990 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	1ea080e7          	jalr	490(ra) # 800060b0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	006080e7          	jalr	6(ra) # 80001ed4 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	3ba50513          	addi	a0,a0,954 # 800082a0 <digits+0x260>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	39a50513          	addi	a0,a0,922 # 800082a0 <digits+0x260>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	a32080e7          	jalr	-1486(ra) # 80002968 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	a52080e7          	jalr	-1454(ra) # 80002990 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	154080e7          	jalr	340(ra) # 8000609a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	162080e7          	jalr	354(ra) # 800060b0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	2de080e7          	jalr	734(ra) # 80003234 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	982080e7          	jalr	-1662(ra) # 800038e0 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	920080e7          	jalr	-1760(ra) # 80004886 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	24a080e7          	jalr	586(ra) # 800061b8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d40080e7          	jalr	-704(ra) # 80001cb6 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	94f72a23          	sw	a5,-1708(a4) # 800088d8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9487b783          	ld	a5,-1720(a5) # 800088e0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	68a7b623          	sd	a0,1676(a5) # 800088e0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6cc080e7          	jalr	1740(ra) # 800009ea <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	767d                	lui	a2,0xfffff
    800013e4:	8f71                	and	a4,a4,a2
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff1                	and	a5,a5,a2
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a821                	j	800014f4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e0:	0532                	slli	a0,a0,0xc
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	fe0080e7          	jalr	-32(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ee:	04a1                	addi	s1,s1,8
    800014f0:	03248163          	beq	s1,s2,80001512 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014f4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	00f57793          	andi	a5,a0,15
    800014fa:	ff3782e3          	beq	a5,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fe:	8905                	andi	a0,a0,1
    80001500:	d57d                	beqz	a0,800014ee <freewalk+0x2c>
      panic("freewalk: leaf");
    80001502:	00007517          	auipc	a0,0x7
    80001506:	c7650513          	addi	a0,a0,-906 # 80008178 <digits+0x138>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001512:	8552                	mv	a0,s4
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	4d6080e7          	jalr	1238(ra) # 800009ea <kfree>
}
    8000151c:	70a2                	ld	ra,40(sp)
    8000151e:	7402                	ld	s0,32(sp)
    80001520:	64e2                	ld	s1,24(sp)
    80001522:	6942                	ld	s2,16(sp)
    80001524:	69a2                	ld	s3,8(sp)
    80001526:	6a02                	ld	s4,0(sp)
    80001528:	6145                	addi	sp,sp,48
    8000152a:	8082                	ret

000000008000152c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152c:	1101                	addi	sp,sp,-32
    8000152e:	ec06                	sd	ra,24(sp)
    80001530:	e822                	sd	s0,16(sp)
    80001532:	e426                	sd	s1,8(sp)
    80001534:	1000                	addi	s0,sp,32
    80001536:	84aa                	mv	s1,a0
  if(sz > 0)
    80001538:	e999                	bnez	a1,8000154e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153a:	8526                	mv	a0,s1
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f86080e7          	jalr	-122(ra) # 800014c2 <freewalk>
}
    80001544:	60e2                	ld	ra,24(sp)
    80001546:	6442                	ld	s0,16(sp)
    80001548:	64a2                	ld	s1,8(sp)
    8000154a:	6105                	addi	sp,sp,32
    8000154c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154e:	6605                	lui	a2,0x1
    80001550:	167d                	addi	a2,a2,-1
    80001552:	962e                	add	a2,a2,a1
    80001554:	4685                	li	a3,1
    80001556:	8231                	srli	a2,a2,0xc
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	d0a080e7          	jalr	-758(ra) # 80001264 <uvmunmap>
    80001562:	bfe1                	j	8000153a <uvmfree+0xe>

0000000080001564 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001564:	c679                	beqz	a2,80001632 <uvmcopy+0xce>
{
    80001566:	715d                	addi	sp,sp,-80
    80001568:	e486                	sd	ra,72(sp)
    8000156a:	e0a2                	sd	s0,64(sp)
    8000156c:	fc26                	sd	s1,56(sp)
    8000156e:	f84a                	sd	s2,48(sp)
    80001570:	f44e                	sd	s3,40(sp)
    80001572:	f052                	sd	s4,32(sp)
    80001574:	ec56                	sd	s5,24(sp)
    80001576:	e85a                	sd	s6,16(sp)
    80001578:	e45e                	sd	s7,8(sp)
    8000157a:	0880                	addi	s0,sp,80
    8000157c:	8b2a                	mv	s6,a0
    8000157e:	8aae                	mv	s5,a1
    80001580:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001582:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001584:	4601                	li	a2,0
    80001586:	85ce                	mv	a1,s3
    80001588:	855a                	mv	a0,s6
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	a2c080e7          	jalr	-1492(ra) # 80000fb6 <walk>
    80001592:	c531                	beqz	a0,800015de <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001594:	6118                	ld	a4,0(a0)
    80001596:	00177793          	andi	a5,a4,1
    8000159a:	cbb1                	beqz	a5,800015ee <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159c:	00a75593          	srli	a1,a4,0xa
    800015a0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800015b0:	892a                	mv	s2,a0
    800015b2:	c939                	beqz	a0,80001608 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85de                	mv	a1,s7
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	776080e7          	jalr	1910(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c0:	8726                	mv	a4,s1
    800015c2:	86ca                	mv	a3,s2
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85ce                	mv	a1,s3
    800015c8:	8556                	mv	a0,s5
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	ad4080e7          	jalr	-1324(ra) # 8000109e <mappages>
    800015d2:	e515                	bnez	a0,800015fe <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d4:	6785                	lui	a5,0x1
    800015d6:	99be                	add	s3,s3,a5
    800015d8:	fb49e6e3          	bltu	s3,s4,80001584 <uvmcopy+0x20>
    800015dc:	a081                	j	8000161c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	baa50513          	addi	a0,a0,-1110 # 80008188 <digits+0x148>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	bba50513          	addi	a0,a0,-1094 # 800081a8 <digits+0x168>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      kfree(mem);
    800015fe:	854a                	mv	a0,s2
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	3ea080e7          	jalr	1002(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001608:	4685                	li	a3,1
    8000160a:	00c9d613          	srli	a2,s3,0xc
    8000160e:	4581                	li	a1,0
    80001610:	8556                	mv	a0,s5
    80001612:	00000097          	auipc	ra,0x0
    80001616:	c52080e7          	jalr	-942(ra) # 80001264 <uvmunmap>
  return -1;
    8000161a:	557d                	li	a0,-1
}
    8000161c:	60a6                	ld	ra,72(sp)
    8000161e:	6406                	ld	s0,64(sp)
    80001620:	74e2                	ld	s1,56(sp)
    80001622:	7942                	ld	s2,48(sp)
    80001624:	79a2                	ld	s3,40(sp)
    80001626:	7a02                	ld	s4,32(sp)
    80001628:	6ae2                	ld	s5,24(sp)
    8000162a:	6b42                	ld	s6,16(sp)
    8000162c:	6ba2                	ld	s7,8(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	976080e7          	jalr	-1674(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b7050513          	addi	a0,a0,-1168 # 800081c8 <digits+0x188>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	9a2080e7          	jalr	-1630(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	604080e7          	jalr	1540(ra) # 80000d2e <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	914080e7          	jalr	-1772(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	882080e7          	jalr	-1918(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4)
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	74448493          	addi	s1,s1,1860 # 80010f90 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	b2aa0a13          	addi	s4,s4,-1238 # 80017390 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8591                	srai	a1,a1,0x4
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	19048493          	addi	s1,s1,400
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7a080e7          	jalr	-902(ra) # 8000053e <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	27850513          	addi	a0,a0,632 # 80010b60 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	27850513          	addi	a0,a0,632 # 80010b78 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	68048493          	addi	s1,s1,1664 # 80010f90 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00016997          	auipc	s3,0x16
    80001936:	a5e98993          	addi	s3,s3,-1442 # 80017390 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8791                	srai	a5,a5,0x4
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	19048493          	addi	s1,s1,400
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	1f450513          	addi	a0,a0,500 # 80010b90 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	19c70713          	addi	a4,a4,412 # 80010b60 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e747a783          	lw	a5,-396(a5) # 80008870 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	fa2080e7          	jalr	-94(ra) # 800029a8 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407ad23          	sw	zero,-422(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	e40080e7          	jalr	-448(ra) # 80003860 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	12a90913          	addi	s2,s2,298 # 80010b60 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e2c78793          	addi	a5,a5,-468 # 80008874 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a52080e7          	jalr	-1454(ra) # 8000152c <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2c080e7          	jalr	-1492(ra) # 8000152c <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e2080e7          	jalr	-1566(ra) # 8000152c <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7c080e7          	jalr	-388(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3ce48493          	addi	s1,s1,974 # 80010f90 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	7c690913          	addi	s2,s2,1990 # 80017390 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	19048493          	addi	s1,s1,400
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a051                	j	80001c78 <allocproc+0xc2>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c93d                	beqz	a0,80001c86 <allocproc+0xd0>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c20:	cd3d                	beqz	a0,80001c9e <allocproc+0xe8>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c46:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c4a:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	ca27a783          	lw	a5,-862(a5) # 800088f0 <ticks>
    80001c56:	16f4a623          	sw	a5,364(s1)
  p->RTime = 0;
    80001c5a:	1604ac23          	sw	zero,376(s1)
  p->STime = 0;
    80001c5e:	1604aa23          	sw	zero,372(s1)
  p->WTime = 0;
    80001c62:	1604ae23          	sw	zero,380(s1)
  p->SP = 50;
    80001c66:	03200793          	li	a5,50
    80001c6a:	18f4a223          	sw	a5,388(s1)
  p->DP = 25;
    80001c6e:	47e5                	li	a5,25
    80001c70:	18f4a423          	sw	a5,392(s1)
  p->scheduled = 0;
    80001c74:	1804a023          	sw	zero,384(s1)
}
    80001c78:	8526                	mv	a0,s1
    80001c7a:	60e2                	ld	ra,24(sp)
    80001c7c:	6442                	ld	s0,16(sp)
    80001c7e:	64a2                	ld	s1,8(sp)
    80001c80:	6902                	ld	s2,0(sp)
    80001c82:	6105                	addi	sp,sp,32
    80001c84:	8082                	ret
    freeproc(p);
    80001c86:	8526                	mv	a0,s1
    80001c88:	00000097          	auipc	ra,0x0
    80001c8c:	ed6080e7          	jalr	-298(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c90:	8526                	mv	a0,s1
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	ff8080e7          	jalr	-8(ra) # 80000c8a <release>
    return 0;
    80001c9a:	84ca                	mv	s1,s2
    80001c9c:	bff1                	j	80001c78 <allocproc+0xc2>
    freeproc(p);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	ebe080e7          	jalr	-322(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001ca8:	8526                	mv	a0,s1
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	fe0080e7          	jalr	-32(ra) # 80000c8a <release>
    return 0;
    80001cb2:	84ca                	mv	s1,s2
    80001cb4:	b7d1                	j	80001c78 <allocproc+0xc2>

0000000080001cb6 <userinit>:
{
    80001cb6:	1101                	addi	sp,sp,-32
    80001cb8:	ec06                	sd	ra,24(sp)
    80001cba:	e822                	sd	s0,16(sp)
    80001cbc:	e426                	sd	s1,8(sp)
    80001cbe:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc0:	00000097          	auipc	ra,0x0
    80001cc4:	ef6080e7          	jalr	-266(ra) # 80001bb6 <allocproc>
    80001cc8:	84aa                	mv	s1,a0
  initproc = p;
    80001cca:	00007797          	auipc	a5,0x7
    80001cce:	c0a7bf23          	sd	a0,-994(a5) # 800088e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cd2:	03400613          	li	a2,52
    80001cd6:	00007597          	auipc	a1,0x7
    80001cda:	baa58593          	addi	a1,a1,-1110 # 80008880 <initcode>
    80001cde:	6928                	ld	a0,80(a0)
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	676080e7          	jalr	1654(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001ce8:	6785                	lui	a5,0x1
    80001cea:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cec:	6cb8                	ld	a4,88(s1)
    80001cee:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cf2:	6cb8                	ld	a4,88(s1)
    80001cf4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf6:	4641                	li	a2,16
    80001cf8:	00006597          	auipc	a1,0x6
    80001cfc:	50858593          	addi	a1,a1,1288 # 80008200 <digits+0x1c0>
    80001d00:	15848513          	addi	a0,s1,344
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	118080e7          	jalr	280(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d0c:	00006517          	auipc	a0,0x6
    80001d10:	50450513          	addi	a0,a0,1284 # 80008210 <digits+0x1d0>
    80001d14:	00002097          	auipc	ra,0x2
    80001d18:	56e080e7          	jalr	1390(ra) # 80004282 <namei>
    80001d1c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d20:	478d                	li	a5,3
    80001d22:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d24:	8526                	mv	a0,s1
    80001d26:	fffff097          	auipc	ra,0xfffff
    80001d2a:	f64080e7          	jalr	-156(ra) # 80000c8a <release>
}
    80001d2e:	60e2                	ld	ra,24(sp)
    80001d30:	6442                	ld	s0,16(sp)
    80001d32:	64a2                	ld	s1,8(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret

0000000080001d38 <growproc>:
{
    80001d38:	1101                	addi	sp,sp,-32
    80001d3a:	ec06                	sd	ra,24(sp)
    80001d3c:	e822                	sd	s0,16(sp)
    80001d3e:	e426                	sd	s1,8(sp)
    80001d40:	e04a                	sd	s2,0(sp)
    80001d42:	1000                	addi	s0,sp,32
    80001d44:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d46:	00000097          	auipc	ra,0x0
    80001d4a:	c66080e7          	jalr	-922(ra) # 800019ac <myproc>
    80001d4e:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d50:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d52:	01204c63          	bgtz	s2,80001d6a <growproc+0x32>
  else if (n < 0)
    80001d56:	02094663          	bltz	s2,80001d82 <growproc+0x4a>
  p->sz = sz;
    80001d5a:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d5c:	4501                	li	a0,0
}
    80001d5e:	60e2                	ld	ra,24(sp)
    80001d60:	6442                	ld	s0,16(sp)
    80001d62:	64a2                	ld	s1,8(sp)
    80001d64:	6902                	ld	s2,0(sp)
    80001d66:	6105                	addi	sp,sp,32
    80001d68:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d6a:	4691                	li	a3,4
    80001d6c:	00b90633          	add	a2,s2,a1
    80001d70:	6928                	ld	a0,80(a0)
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	69e080e7          	jalr	1694(ra) # 80001410 <uvmalloc>
    80001d7a:	85aa                	mv	a1,a0
    80001d7c:	fd79                	bnez	a0,80001d5a <growproc+0x22>
      return -1;
    80001d7e:	557d                	li	a0,-1
    80001d80:	bff9                	j	80001d5e <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d82:	00b90633          	add	a2,s2,a1
    80001d86:	6928                	ld	a0,80(a0)
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	640080e7          	jalr	1600(ra) # 800013c8 <uvmdealloc>
    80001d90:	85aa                	mv	a1,a0
    80001d92:	b7e1                	j	80001d5a <growproc+0x22>

0000000080001d94 <fork>:
{
    80001d94:	7139                	addi	sp,sp,-64
    80001d96:	fc06                	sd	ra,56(sp)
    80001d98:	f822                	sd	s0,48(sp)
    80001d9a:	f426                	sd	s1,40(sp)
    80001d9c:	f04a                	sd	s2,32(sp)
    80001d9e:	ec4e                	sd	s3,24(sp)
    80001da0:	e852                	sd	s4,16(sp)
    80001da2:	e456                	sd	s5,8(sp)
    80001da4:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001da6:	00000097          	auipc	ra,0x0
    80001daa:	c06080e7          	jalr	-1018(ra) # 800019ac <myproc>
    80001dae:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001db0:	00000097          	auipc	ra,0x0
    80001db4:	e06080e7          	jalr	-506(ra) # 80001bb6 <allocproc>
    80001db8:	10050c63          	beqz	a0,80001ed0 <fork+0x13c>
    80001dbc:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dbe:	048ab603          	ld	a2,72(s5)
    80001dc2:	692c                	ld	a1,80(a0)
    80001dc4:	050ab503          	ld	a0,80(s5)
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	79c080e7          	jalr	1948(ra) # 80001564 <uvmcopy>
    80001dd0:	04054863          	bltz	a0,80001e20 <fork+0x8c>
  np->sz = p->sz;
    80001dd4:	048ab783          	ld	a5,72(s5)
    80001dd8:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001ddc:	058ab683          	ld	a3,88(s5)
    80001de0:	87b6                	mv	a5,a3
    80001de2:	058a3703          	ld	a4,88(s4)
    80001de6:	12068693          	addi	a3,a3,288
    80001dea:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dee:	6788                	ld	a0,8(a5)
    80001df0:	6b8c                	ld	a1,16(a5)
    80001df2:	6f90                	ld	a2,24(a5)
    80001df4:	01073023          	sd	a6,0(a4)
    80001df8:	e708                	sd	a0,8(a4)
    80001dfa:	eb0c                	sd	a1,16(a4)
    80001dfc:	ef10                	sd	a2,24(a4)
    80001dfe:	02078793          	addi	a5,a5,32
    80001e02:	02070713          	addi	a4,a4,32
    80001e06:	fed792e3          	bne	a5,a3,80001dea <fork+0x56>
  np->trapframe->a0 = 0;
    80001e0a:	058a3783          	ld	a5,88(s4)
    80001e0e:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e12:	0d0a8493          	addi	s1,s5,208
    80001e16:	0d0a0913          	addi	s2,s4,208
    80001e1a:	150a8993          	addi	s3,s5,336
    80001e1e:	a00d                	j	80001e40 <fork+0xac>
    freeproc(np);
    80001e20:	8552                	mv	a0,s4
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	d3c080e7          	jalr	-708(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e2a:	8552                	mv	a0,s4
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	e5e080e7          	jalr	-418(ra) # 80000c8a <release>
    return -1;
    80001e34:	597d                	li	s2,-1
    80001e36:	a059                	j	80001ebc <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e38:	04a1                	addi	s1,s1,8
    80001e3a:	0921                	addi	s2,s2,8
    80001e3c:	01348b63          	beq	s1,s3,80001e52 <fork+0xbe>
    if (p->ofile[i])
    80001e40:	6088                	ld	a0,0(s1)
    80001e42:	d97d                	beqz	a0,80001e38 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e44:	00003097          	auipc	ra,0x3
    80001e48:	ad4080e7          	jalr	-1324(ra) # 80004918 <filedup>
    80001e4c:	00a93023          	sd	a0,0(s2)
    80001e50:	b7e5                	j	80001e38 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e52:	150ab503          	ld	a0,336(s5)
    80001e56:	00002097          	auipc	ra,0x2
    80001e5a:	c48080e7          	jalr	-952(ra) # 80003a9e <idup>
    80001e5e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e62:	4641                	li	a2,16
    80001e64:	158a8593          	addi	a1,s5,344
    80001e68:	158a0513          	addi	a0,s4,344
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	fb0080e7          	jalr	-80(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e74:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e78:	8552                	mv	a0,s4
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	e10080e7          	jalr	-496(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e82:	0000f497          	auipc	s1,0xf
    80001e86:	cf648493          	addi	s1,s1,-778 # 80010b78 <wait_lock>
    80001e8a:	8526                	mv	a0,s1
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	d4a080e7          	jalr	-694(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e94:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e98:	8526                	mv	a0,s1
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	df0080e7          	jalr	-528(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001ea2:	8552                	mv	a0,s4
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	d32080e7          	jalr	-718(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001eac:	478d                	li	a5,3
    80001eae:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001eb2:	8552                	mv	a0,s4
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	dd6080e7          	jalr	-554(ra) # 80000c8a <release>
}
    80001ebc:	854a                	mv	a0,s2
    80001ebe:	70e2                	ld	ra,56(sp)
    80001ec0:	7442                	ld	s0,48(sp)
    80001ec2:	74a2                	ld	s1,40(sp)
    80001ec4:	7902                	ld	s2,32(sp)
    80001ec6:	69e2                	ld	s3,24(sp)
    80001ec8:	6a42                	ld	s4,16(sp)
    80001eca:	6aa2                	ld	s5,8(sp)
    80001ecc:	6121                	addi	sp,sp,64
    80001ece:	8082                	ret
    return -1;
    80001ed0:	597d                	li	s2,-1
    80001ed2:	b7ed                	j	80001ebc <fork+0x128>

0000000080001ed4 <scheduler>:
{
    80001ed4:	7119                	addi	sp,sp,-128
    80001ed6:	fc86                	sd	ra,120(sp)
    80001ed8:	f8a2                	sd	s0,112(sp)
    80001eda:	f4a6                	sd	s1,104(sp)
    80001edc:	f0ca                	sd	s2,96(sp)
    80001ede:	ecce                	sd	s3,88(sp)
    80001ee0:	e8d2                	sd	s4,80(sp)
    80001ee2:	e4d6                	sd	s5,72(sp)
    80001ee4:	e0da                	sd	s6,64(sp)
    80001ee6:	fc5e                	sd	s7,56(sp)
    80001ee8:	f862                	sd	s8,48(sp)
    80001eea:	f466                	sd	s9,40(sp)
    80001eec:	f06a                	sd	s10,32(sp)
    80001eee:	ec6e                	sd	s11,24(sp)
    80001ef0:	0100                	addi	s0,sp,128
    80001ef2:	8792                	mv	a5,tp
  int id = r_tp();
    80001ef4:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ef6:	00779693          	slli	a3,a5,0x7
    80001efa:	0000f717          	auipc	a4,0xf
    80001efe:	c6670713          	addi	a4,a4,-922 # 80010b60 <pid_lock>
    80001f02:	9736                	add	a4,a4,a3
    80001f04:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &process_with_highest_priority->context);
    80001f08:	0000f717          	auipc	a4,0xf
    80001f0c:	c9070713          	addi	a4,a4,-880 # 80010b98 <cpus+0x8>
    80001f10:	9736                	add	a4,a4,a3
    80001f12:	f8e43423          	sd	a4,-120(s0)
    for (p = proc; p < &proc[NPROC]; p++)
    80001f16:	00015b17          	auipc	s6,0x15
    80001f1a:	47ab0b13          	addi	s6,s6,1146 # 80017390 <tickslock>
        tempRBI = tempRBI * 50;
    80001f1e:	03200c13          	li	s8,50
        c->proc = process_with_highest_priority;
    80001f22:	0000f717          	auipc	a4,0xf
    80001f26:	c3e70713          	addi	a4,a4,-962 # 80010b60 <pid_lock>
    80001f2a:	00d707b3          	add	a5,a4,a3
    80001f2e:	f8f43023          	sd	a5,-128(s0)
    80001f32:	a0d9                	j	80001ff8 <scheduler+0x124>
        int tempRBI = 3 * p->RTime - p->STime - p->WTime;
    80001f34:	fe84a703          	lw	a4,-24(s1)
    80001f38:	fe44a683          	lw	a3,-28(s1)
    80001f3c:	fec4a603          	lw	a2,-20(s1)
    80001f40:	0017179b          	slliw	a5,a4,0x1
    80001f44:	9fb9                	addw	a5,a5,a4
    80001f46:	9f95                	subw	a5,a5,a3
    80001f48:	9f91                	subw	a5,a5,a2
        tempRBI = tempRBI * 50;
    80001f4a:	02fc07bb          	mulw	a5,s8,a5
        int tempD = p->RTime + p->WTime + p->STime + 1;
    80001f4e:	9f31                	addw	a4,a4,a2
    80001f50:	9f35                	addw	a4,a4,a3
    80001f52:	2705                	addiw	a4,a4,1
        tempRBI = (int)tempRBI / tempD;
    80001f54:	02e7c7bb          	divw	a5,a5,a4
        int tempDP = p->SP + RBI;
    80001f58:	0007871b          	sext.w	a4,a5
    80001f5c:	fff74713          	not	a4,a4
    80001f60:	977d                	srai	a4,a4,0x3f
    80001f62:	8ff9                	and	a5,a5,a4
    80001f64:	ff44a703          	lw	a4,-12(s1)
    80001f68:	9fb9                	addw	a5,a5,a4
        if (tempDP > 100)
    80001f6a:	873e                	mv	a4,a5
    80001f6c:	2781                	sext.w	a5,a5
    80001f6e:	00fcd363          	bge	s9,a5,80001f74 <scheduler+0xa0>
    80001f72:	876a                	mv	a4,s10
    80001f74:	0007079b          	sext.w	a5,a4
        p->DP = tempDP;
    80001f78:	fee9ac23          	sw	a4,-8(s3)
        if (process_with_highest_priority == 0)
    80001f7c:	080b8463          	beqz	s7,80002004 <scheduler+0x130>
        else if (process_with_highest_priority->DP > p->DP)
    80001f80:	188ba703          	lw	a4,392(s7) # fffffffffffff188 <end+0xffffffff7ffdca18>
    80001f84:	08e7c263          	blt	a5,a4,80002008 <scheduler+0x134>
        else if (process_with_highest_priority->DP == p->DP)
    80001f88:	08e79163          	bne	a5,a4,8000200a <scheduler+0x136>
          if (process_with_highest_priority->scheduled > p->scheduled)
    80001f8c:	180ba703          	lw	a4,384(s7)
    80001f90:	ff09a783          	lw	a5,-16(s3)
    80001f94:	0ce7cb63          	blt	a5,a4,8000206a <scheduler+0x196>
          else if (process_with_highest_priority->scheduled == p->scheduled)
    80001f98:	06f71963          	bne	a4,a5,8000200a <scheduler+0x136>
            if (process_with_highest_priority->ctime > p->ctime)
    80001f9c:	16cba703          	lw	a4,364(s7)
    80001fa0:	fdc9a783          	lw	a5,-36(s3)
    80001fa4:	06e7f363          	bgeu	a5,a4,8000200a <scheduler+0x136>
    80001fa8:	8bd2                	mv	s7,s4
    80001faa:	a085                	j	8000200a <scheduler+0x136>
      acquire(&process_with_highest_priority->lock);
    80001fac:	84de                	mv	s1,s7
    80001fae:	855e                	mv	a0,s7
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	c26080e7          	jalr	-986(ra) # 80000bd6 <acquire>
      if (process_with_highest_priority->state == RUNNABLE)
    80001fb8:	018ba703          	lw	a4,24(s7)
    80001fbc:	478d                	li	a5,3
    80001fbe:	02f71863          	bne	a4,a5,80001fee <scheduler+0x11a>
        process_with_highest_priority->state = RUNNING;
    80001fc2:	4791                	li	a5,4
    80001fc4:	00fbac23          	sw	a5,24(s7)
        process_with_highest_priority->scheduled++;
    80001fc8:	180ba783          	lw	a5,384(s7)
    80001fcc:	2785                	addiw	a5,a5,1
    80001fce:	18fba023          	sw	a5,384(s7)
        c->proc = process_with_highest_priority;
    80001fd2:	f8043903          	ld	s2,-128(s0)
    80001fd6:	03793823          	sd	s7,48(s2)
        swtch(&c->context, &process_with_highest_priority->context);
    80001fda:	060b8593          	addi	a1,s7,96
    80001fde:	f8843503          	ld	a0,-120(s0)
    80001fe2:	00001097          	auipc	ra,0x1
    80001fe6:	91c080e7          	jalr	-1764(ra) # 800028fe <swtch>
        c->proc = 0;
    80001fea:	02093823          	sd	zero,48(s2)
      release(&process_with_highest_priority->lock);
    80001fee:	8526                	mv	a0,s1
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	c9a080e7          	jalr	-870(ra) # 80000c8a <release>
    struct proc *process_with_highest_priority = 0;
    80001ff8:	4d81                	li	s11,0
    80001ffa:	06400c93          	li	s9,100
    80001ffe:	06400d13          	li	s10,100
    80002002:	a099                	j	80002048 <scheduler+0x174>
    80002004:	8bd2                	mv	s7,s4
    80002006:	a011                	j	8000200a <scheduler+0x136>
    80002008:	8bd2                	mv	s7,s4
      release(&p->lock);
    8000200a:	8552                	mv	a0,s4
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	c7e080e7          	jalr	-898(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002014:	f969fce3          	bgeu	s3,s6,80001fac <scheduler+0xd8>
    80002018:	19090913          	addi	s2,s2,400
    8000201c:	19048493          	addi	s1,s1,400
    80002020:	8a4a                	mv	s4,s2
      acquire(&p->lock);
    80002022:	854a                	mv	a0,s2
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	bb2080e7          	jalr	-1102(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    8000202c:	89a6                	mv	s3,s1
    8000202e:	e884a783          	lw	a5,-376(s1)
    80002032:	f15781e3          	beq	a5,s5,80001f34 <scheduler+0x60>
      release(&p->lock);
    80002036:	854a                	mv	a0,s2
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	c52080e7          	jalr	-942(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002040:	fd64ece3          	bltu	s1,s6,80002018 <scheduler+0x144>
    if (process_with_highest_priority)
    80002044:	f60b94e3          	bnez	s7,80001fac <scheduler+0xd8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002048:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000204c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002050:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002054:	0000f917          	auipc	s2,0xf
    80002058:	f3c90913          	addi	s2,s2,-196 # 80010f90 <proc>
    8000205c:	0000f497          	auipc	s1,0xf
    80002060:	0c448493          	addi	s1,s1,196 # 80011120 <proc+0x190>
    struct proc *process_with_highest_priority = 0;
    80002064:	8bee                	mv	s7,s11
      if (p->state == RUNNABLE)
    80002066:	4a8d                	li	s5,3
    80002068:	bf65                	j	80002020 <scheduler+0x14c>
    8000206a:	8bd2                	mv	s7,s4
    8000206c:	bf79                	j	8000200a <scheduler+0x136>

000000008000206e <sched>:
{
    8000206e:	7179                	addi	sp,sp,-48
    80002070:	f406                	sd	ra,40(sp)
    80002072:	f022                	sd	s0,32(sp)
    80002074:	ec26                	sd	s1,24(sp)
    80002076:	e84a                	sd	s2,16(sp)
    80002078:	e44e                	sd	s3,8(sp)
    8000207a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	930080e7          	jalr	-1744(ra) # 800019ac <myproc>
    80002084:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	ad6080e7          	jalr	-1322(ra) # 80000b5c <holding>
    8000208e:	c93d                	beqz	a0,80002104 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002090:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002092:	2781                	sext.w	a5,a5
    80002094:	079e                	slli	a5,a5,0x7
    80002096:	0000f717          	auipc	a4,0xf
    8000209a:	aca70713          	addi	a4,a4,-1334 # 80010b60 <pid_lock>
    8000209e:	97ba                	add	a5,a5,a4
    800020a0:	0a87a703          	lw	a4,168(a5)
    800020a4:	4785                	li	a5,1
    800020a6:	06f71763          	bne	a4,a5,80002114 <sched+0xa6>
  if (p->state == RUNNING)
    800020aa:	4c98                	lw	a4,24(s1)
    800020ac:	4791                	li	a5,4
    800020ae:	06f70b63          	beq	a4,a5,80002124 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020b2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020b6:	8b89                	andi	a5,a5,2
  if (intr_get())
    800020b8:	efb5                	bnez	a5,80002134 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ba:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020bc:	0000f917          	auipc	s2,0xf
    800020c0:	aa490913          	addi	s2,s2,-1372 # 80010b60 <pid_lock>
    800020c4:	2781                	sext.w	a5,a5
    800020c6:	079e                	slli	a5,a5,0x7
    800020c8:	97ca                	add	a5,a5,s2
    800020ca:	0ac7a983          	lw	s3,172(a5)
    800020ce:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020d0:	2781                	sext.w	a5,a5
    800020d2:	079e                	slli	a5,a5,0x7
    800020d4:	0000f597          	auipc	a1,0xf
    800020d8:	ac458593          	addi	a1,a1,-1340 # 80010b98 <cpus+0x8>
    800020dc:	95be                	add	a1,a1,a5
    800020de:	06048513          	addi	a0,s1,96
    800020e2:	00001097          	auipc	ra,0x1
    800020e6:	81c080e7          	jalr	-2020(ra) # 800028fe <swtch>
    800020ea:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020ec:	2781                	sext.w	a5,a5
    800020ee:	079e                	slli	a5,a5,0x7
    800020f0:	97ca                	add	a5,a5,s2
    800020f2:	0b37a623          	sw	s3,172(a5)
}
    800020f6:	70a2                	ld	ra,40(sp)
    800020f8:	7402                	ld	s0,32(sp)
    800020fa:	64e2                	ld	s1,24(sp)
    800020fc:	6942                	ld	s2,16(sp)
    800020fe:	69a2                	ld	s3,8(sp)
    80002100:	6145                	addi	sp,sp,48
    80002102:	8082                	ret
    panic("sched p->lock");
    80002104:	00006517          	auipc	a0,0x6
    80002108:	11450513          	addi	a0,a0,276 # 80008218 <digits+0x1d8>
    8000210c:	ffffe097          	auipc	ra,0xffffe
    80002110:	432080e7          	jalr	1074(ra) # 8000053e <panic>
    panic("sched locks");
    80002114:	00006517          	auipc	a0,0x6
    80002118:	11450513          	addi	a0,a0,276 # 80008228 <digits+0x1e8>
    8000211c:	ffffe097          	auipc	ra,0xffffe
    80002120:	422080e7          	jalr	1058(ra) # 8000053e <panic>
    panic("sched running");
    80002124:	00006517          	auipc	a0,0x6
    80002128:	11450513          	addi	a0,a0,276 # 80008238 <digits+0x1f8>
    8000212c:	ffffe097          	auipc	ra,0xffffe
    80002130:	412080e7          	jalr	1042(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002134:	00006517          	auipc	a0,0x6
    80002138:	11450513          	addi	a0,a0,276 # 80008248 <digits+0x208>
    8000213c:	ffffe097          	auipc	ra,0xffffe
    80002140:	402080e7          	jalr	1026(ra) # 8000053e <panic>

0000000080002144 <yield>:
{
    80002144:	1101                	addi	sp,sp,-32
    80002146:	ec06                	sd	ra,24(sp)
    80002148:	e822                	sd	s0,16(sp)
    8000214a:	e426                	sd	s1,8(sp)
    8000214c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000214e:	00000097          	auipc	ra,0x0
    80002152:	85e080e7          	jalr	-1954(ra) # 800019ac <myproc>
    80002156:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	a7e080e7          	jalr	-1410(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002160:	478d                	li	a5,3
    80002162:	cc9c                	sw	a5,24(s1)
  sched();
    80002164:	00000097          	auipc	ra,0x0
    80002168:	f0a080e7          	jalr	-246(ra) # 8000206e <sched>
  release(&p->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b1c080e7          	jalr	-1252(ra) # 80000c8a <release>
}
    80002176:	60e2                	ld	ra,24(sp)
    80002178:	6442                	ld	s0,16(sp)
    8000217a:	64a2                	ld	s1,8(sp)
    8000217c:	6105                	addi	sp,sp,32
    8000217e:	8082                	ret

0000000080002180 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002180:	7179                	addi	sp,sp,-48
    80002182:	f406                	sd	ra,40(sp)
    80002184:	f022                	sd	s0,32(sp)
    80002186:	ec26                	sd	s1,24(sp)
    80002188:	e84a                	sd	s2,16(sp)
    8000218a:	e44e                	sd	s3,8(sp)
    8000218c:	1800                	addi	s0,sp,48
    8000218e:	89aa                	mv	s3,a0
    80002190:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002192:	00000097          	auipc	ra,0x0
    80002196:	81a080e7          	jalr	-2022(ra) # 800019ac <myproc>
    8000219a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	a3a080e7          	jalr	-1478(ra) # 80000bd6 <acquire>
  release(lk);
    800021a4:	854a                	mv	a0,s2
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	ae4080e7          	jalr	-1308(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800021ae:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021b2:	4789                	li	a5,2
    800021b4:	cc9c                	sw	a5,24(s1)

  sched();
    800021b6:	00000097          	auipc	ra,0x0
    800021ba:	eb8080e7          	jalr	-328(ra) # 8000206e <sched>

  // Tidy up.
  p->chan = 0;
    800021be:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	ac6080e7          	jalr	-1338(ra) # 80000c8a <release>
  acquire(lk);
    800021cc:	854a                	mv	a0,s2
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	a08080e7          	jalr	-1528(ra) # 80000bd6 <acquire>
}
    800021d6:	70a2                	ld	ra,40(sp)
    800021d8:	7402                	ld	s0,32(sp)
    800021da:	64e2                	ld	s1,24(sp)
    800021dc:	6942                	ld	s2,16(sp)
    800021de:	69a2                	ld	s3,8(sp)
    800021e0:	6145                	addi	sp,sp,48
    800021e2:	8082                	ret

00000000800021e4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800021e4:	7139                	addi	sp,sp,-64
    800021e6:	fc06                	sd	ra,56(sp)
    800021e8:	f822                	sd	s0,48(sp)
    800021ea:	f426                	sd	s1,40(sp)
    800021ec:	f04a                	sd	s2,32(sp)
    800021ee:	ec4e                	sd	s3,24(sp)
    800021f0:	e852                	sd	s4,16(sp)
    800021f2:	e456                	sd	s5,8(sp)
    800021f4:	0080                	addi	s0,sp,64
    800021f6:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800021f8:	0000f497          	auipc	s1,0xf
    800021fc:	d9848493          	addi	s1,s1,-616 # 80010f90 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002200:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002202:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002204:	00015917          	auipc	s2,0x15
    80002208:	18c90913          	addi	s2,s2,396 # 80017390 <tickslock>
    8000220c:	a811                	j	80002220 <wakeup+0x3c>
      }
      release(&p->lock);
    8000220e:	8526                	mv	a0,s1
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	a7a080e7          	jalr	-1414(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002218:	19048493          	addi	s1,s1,400
    8000221c:	03248663          	beq	s1,s2,80002248 <wakeup+0x64>
    if (p != myproc())
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	78c080e7          	jalr	1932(ra) # 800019ac <myproc>
    80002228:	fea488e3          	beq	s1,a0,80002218 <wakeup+0x34>
      acquire(&p->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	9a8080e7          	jalr	-1624(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002236:	4c9c                	lw	a5,24(s1)
    80002238:	fd379be3          	bne	a5,s3,8000220e <wakeup+0x2a>
    8000223c:	709c                	ld	a5,32(s1)
    8000223e:	fd4798e3          	bne	a5,s4,8000220e <wakeup+0x2a>
        p->state = RUNNABLE;
    80002242:	0154ac23          	sw	s5,24(s1)
    80002246:	b7e1                	j	8000220e <wakeup+0x2a>
    }
  }
}
    80002248:	70e2                	ld	ra,56(sp)
    8000224a:	7442                	ld	s0,48(sp)
    8000224c:	74a2                	ld	s1,40(sp)
    8000224e:	7902                	ld	s2,32(sp)
    80002250:	69e2                	ld	s3,24(sp)
    80002252:	6a42                	ld	s4,16(sp)
    80002254:	6aa2                	ld	s5,8(sp)
    80002256:	6121                	addi	sp,sp,64
    80002258:	8082                	ret

000000008000225a <reparent>:
{
    8000225a:	7179                	addi	sp,sp,-48
    8000225c:	f406                	sd	ra,40(sp)
    8000225e:	f022                	sd	s0,32(sp)
    80002260:	ec26                	sd	s1,24(sp)
    80002262:	e84a                	sd	s2,16(sp)
    80002264:	e44e                	sd	s3,8(sp)
    80002266:	e052                	sd	s4,0(sp)
    80002268:	1800                	addi	s0,sp,48
    8000226a:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000226c:	0000f497          	auipc	s1,0xf
    80002270:	d2448493          	addi	s1,s1,-732 # 80010f90 <proc>
      pp->parent = initproc;
    80002274:	00006a17          	auipc	s4,0x6
    80002278:	674a0a13          	addi	s4,s4,1652 # 800088e8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000227c:	00015997          	auipc	s3,0x15
    80002280:	11498993          	addi	s3,s3,276 # 80017390 <tickslock>
    80002284:	a029                	j	8000228e <reparent+0x34>
    80002286:	19048493          	addi	s1,s1,400
    8000228a:	01348d63          	beq	s1,s3,800022a4 <reparent+0x4a>
    if (pp->parent == p)
    8000228e:	7c9c                	ld	a5,56(s1)
    80002290:	ff279be3          	bne	a5,s2,80002286 <reparent+0x2c>
      pp->parent = initproc;
    80002294:	000a3503          	ld	a0,0(s4)
    80002298:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000229a:	00000097          	auipc	ra,0x0
    8000229e:	f4a080e7          	jalr	-182(ra) # 800021e4 <wakeup>
    800022a2:	b7d5                	j	80002286 <reparent+0x2c>
}
    800022a4:	70a2                	ld	ra,40(sp)
    800022a6:	7402                	ld	s0,32(sp)
    800022a8:	64e2                	ld	s1,24(sp)
    800022aa:	6942                	ld	s2,16(sp)
    800022ac:	69a2                	ld	s3,8(sp)
    800022ae:	6a02                	ld	s4,0(sp)
    800022b0:	6145                	addi	sp,sp,48
    800022b2:	8082                	ret

00000000800022b4 <exit>:
{
    800022b4:	7179                	addi	sp,sp,-48
    800022b6:	f406                	sd	ra,40(sp)
    800022b8:	f022                	sd	s0,32(sp)
    800022ba:	ec26                	sd	s1,24(sp)
    800022bc:	e84a                	sd	s2,16(sp)
    800022be:	e44e                	sd	s3,8(sp)
    800022c0:	e052                	sd	s4,0(sp)
    800022c2:	1800                	addi	s0,sp,48
    800022c4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	6e6080e7          	jalr	1766(ra) # 800019ac <myproc>
    800022ce:	89aa                	mv	s3,a0
  if (p == initproc)
    800022d0:	00006797          	auipc	a5,0x6
    800022d4:	6187b783          	ld	a5,1560(a5) # 800088e8 <initproc>
    800022d8:	0d050493          	addi	s1,a0,208
    800022dc:	15050913          	addi	s2,a0,336
    800022e0:	02a79363          	bne	a5,a0,80002306 <exit+0x52>
    panic("init exiting");
    800022e4:	00006517          	auipc	a0,0x6
    800022e8:	f7c50513          	addi	a0,a0,-132 # 80008260 <digits+0x220>
    800022ec:	ffffe097          	auipc	ra,0xffffe
    800022f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
      fileclose(f);
    800022f4:	00002097          	auipc	ra,0x2
    800022f8:	676080e7          	jalr	1654(ra) # 8000496a <fileclose>
      p->ofile[fd] = 0;
    800022fc:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002300:	04a1                	addi	s1,s1,8
    80002302:	01248563          	beq	s1,s2,8000230c <exit+0x58>
    if (p->ofile[fd])
    80002306:	6088                	ld	a0,0(s1)
    80002308:	f575                	bnez	a0,800022f4 <exit+0x40>
    8000230a:	bfdd                	j	80002300 <exit+0x4c>
  begin_op();
    8000230c:	00002097          	auipc	ra,0x2
    80002310:	192080e7          	jalr	402(ra) # 8000449e <begin_op>
  iput(p->cwd);
    80002314:	1509b503          	ld	a0,336(s3)
    80002318:	00002097          	auipc	ra,0x2
    8000231c:	97e080e7          	jalr	-1666(ra) # 80003c96 <iput>
  end_op();
    80002320:	00002097          	auipc	ra,0x2
    80002324:	1fe080e7          	jalr	510(ra) # 8000451e <end_op>
  p->cwd = 0;
    80002328:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000232c:	0000f497          	auipc	s1,0xf
    80002330:	84c48493          	addi	s1,s1,-1972 # 80010b78 <wait_lock>
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	8a0080e7          	jalr	-1888(ra) # 80000bd6 <acquire>
  reparent(p);
    8000233e:	854e                	mv	a0,s3
    80002340:	00000097          	auipc	ra,0x0
    80002344:	f1a080e7          	jalr	-230(ra) # 8000225a <reparent>
  wakeup(p->parent);
    80002348:	0389b503          	ld	a0,56(s3)
    8000234c:	00000097          	auipc	ra,0x0
    80002350:	e98080e7          	jalr	-360(ra) # 800021e4 <wakeup>
  acquire(&p->lock);
    80002354:	854e                	mv	a0,s3
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	880080e7          	jalr	-1920(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000235e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002362:	4795                	li	a5,5
    80002364:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002368:	00006797          	auipc	a5,0x6
    8000236c:	5887a783          	lw	a5,1416(a5) # 800088f0 <ticks>
    80002370:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002374:	8526                	mv	a0,s1
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	914080e7          	jalr	-1772(ra) # 80000c8a <release>
  sched();
    8000237e:	00000097          	auipc	ra,0x0
    80002382:	cf0080e7          	jalr	-784(ra) # 8000206e <sched>
  panic("zombie exit");
    80002386:	00006517          	auipc	a0,0x6
    8000238a:	eea50513          	addi	a0,a0,-278 # 80008270 <digits+0x230>
    8000238e:	ffffe097          	auipc	ra,0xffffe
    80002392:	1b0080e7          	jalr	432(ra) # 8000053e <panic>

0000000080002396 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002396:	7179                	addi	sp,sp,-48
    80002398:	f406                	sd	ra,40(sp)
    8000239a:	f022                	sd	s0,32(sp)
    8000239c:	ec26                	sd	s1,24(sp)
    8000239e:	e84a                	sd	s2,16(sp)
    800023a0:	e44e                	sd	s3,8(sp)
    800023a2:	1800                	addi	s0,sp,48
    800023a4:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023a6:	0000f497          	auipc	s1,0xf
    800023aa:	bea48493          	addi	s1,s1,-1046 # 80010f90 <proc>
    800023ae:	00015997          	auipc	s3,0x15
    800023b2:	fe298993          	addi	s3,s3,-30 # 80017390 <tickslock>
  {
    acquire(&p->lock);
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	81e080e7          	jalr	-2018(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800023c0:	589c                	lw	a5,48(s1)
    800023c2:	01278d63          	beq	a5,s2,800023dc <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	8c2080e7          	jalr	-1854(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800023d0:	19048493          	addi	s1,s1,400
    800023d4:	ff3491e3          	bne	s1,s3,800023b6 <kill+0x20>
  }
  return -1;
    800023d8:	557d                	li	a0,-1
    800023da:	a829                	j	800023f4 <kill+0x5e>
      p->killed = 1;
    800023dc:	4785                	li	a5,1
    800023de:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800023e0:	4c98                	lw	a4,24(s1)
    800023e2:	4789                	li	a5,2
    800023e4:	00f70f63          	beq	a4,a5,80002402 <kill+0x6c>
      release(&p->lock);
    800023e8:	8526                	mv	a0,s1
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	8a0080e7          	jalr	-1888(ra) # 80000c8a <release>
      return 0;
    800023f2:	4501                	li	a0,0
}
    800023f4:	70a2                	ld	ra,40(sp)
    800023f6:	7402                	ld	s0,32(sp)
    800023f8:	64e2                	ld	s1,24(sp)
    800023fa:	6942                	ld	s2,16(sp)
    800023fc:	69a2                	ld	s3,8(sp)
    800023fe:	6145                	addi	sp,sp,48
    80002400:	8082                	ret
        p->state = RUNNABLE;
    80002402:	478d                	li	a5,3
    80002404:	cc9c                	sw	a5,24(s1)
    80002406:	b7cd                	j	800023e8 <kill+0x52>

0000000080002408 <setkilled>:

void setkilled(struct proc *p)
{
    80002408:	1101                	addi	sp,sp,-32
    8000240a:	ec06                	sd	ra,24(sp)
    8000240c:	e822                	sd	s0,16(sp)
    8000240e:	e426                	sd	s1,8(sp)
    80002410:	1000                	addi	s0,sp,32
    80002412:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002414:	ffffe097          	auipc	ra,0xffffe
    80002418:	7c2080e7          	jalr	1986(ra) # 80000bd6 <acquire>
  p->killed = 1;
    8000241c:	4785                	li	a5,1
    8000241e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002420:	8526                	mv	a0,s1
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	868080e7          	jalr	-1944(ra) # 80000c8a <release>
}
    8000242a:	60e2                	ld	ra,24(sp)
    8000242c:	6442                	ld	s0,16(sp)
    8000242e:	64a2                	ld	s1,8(sp)
    80002430:	6105                	addi	sp,sp,32
    80002432:	8082                	ret

0000000080002434 <killed>:

int killed(struct proc *p)
{
    80002434:	1101                	addi	sp,sp,-32
    80002436:	ec06                	sd	ra,24(sp)
    80002438:	e822                	sd	s0,16(sp)
    8000243a:	e426                	sd	s1,8(sp)
    8000243c:	e04a                	sd	s2,0(sp)
    8000243e:	1000                	addi	s0,sp,32
    80002440:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002442:	ffffe097          	auipc	ra,0xffffe
    80002446:	794080e7          	jalr	1940(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000244a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	83a080e7          	jalr	-1990(ra) # 80000c8a <release>
  return k;
}
    80002458:	854a                	mv	a0,s2
    8000245a:	60e2                	ld	ra,24(sp)
    8000245c:	6442                	ld	s0,16(sp)
    8000245e:	64a2                	ld	s1,8(sp)
    80002460:	6902                	ld	s2,0(sp)
    80002462:	6105                	addi	sp,sp,32
    80002464:	8082                	ret

0000000080002466 <wait>:
{
    80002466:	715d                	addi	sp,sp,-80
    80002468:	e486                	sd	ra,72(sp)
    8000246a:	e0a2                	sd	s0,64(sp)
    8000246c:	fc26                	sd	s1,56(sp)
    8000246e:	f84a                	sd	s2,48(sp)
    80002470:	f44e                	sd	s3,40(sp)
    80002472:	f052                	sd	s4,32(sp)
    80002474:	ec56                	sd	s5,24(sp)
    80002476:	e85a                	sd	s6,16(sp)
    80002478:	e45e                	sd	s7,8(sp)
    8000247a:	e062                	sd	s8,0(sp)
    8000247c:	0880                	addi	s0,sp,80
    8000247e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	52c080e7          	jalr	1324(ra) # 800019ac <myproc>
    80002488:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000248a:	0000e517          	auipc	a0,0xe
    8000248e:	6ee50513          	addi	a0,a0,1774 # 80010b78 <wait_lock>
    80002492:	ffffe097          	auipc	ra,0xffffe
    80002496:	744080e7          	jalr	1860(ra) # 80000bd6 <acquire>
    havekids = 0;
    8000249a:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000249c:	4a15                	li	s4,5
        havekids = 1;
    8000249e:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024a0:	00015997          	auipc	s3,0x15
    800024a4:	ef098993          	addi	s3,s3,-272 # 80017390 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024a8:	0000ec17          	auipc	s8,0xe
    800024ac:	6d0c0c13          	addi	s8,s8,1744 # 80010b78 <wait_lock>
    havekids = 0;
    800024b0:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024b2:	0000f497          	auipc	s1,0xf
    800024b6:	ade48493          	addi	s1,s1,-1314 # 80010f90 <proc>
    800024ba:	a0bd                	j	80002528 <wait+0xc2>
          pid = pp->pid;
    800024bc:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800024c0:	000b0e63          	beqz	s6,800024dc <wait+0x76>
    800024c4:	4691                	li	a3,4
    800024c6:	02c48613          	addi	a2,s1,44
    800024ca:	85da                	mv	a1,s6
    800024cc:	05093503          	ld	a0,80(s2)
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	198080e7          	jalr	408(ra) # 80001668 <copyout>
    800024d8:	02054563          	bltz	a0,80002502 <wait+0x9c>
          freeproc(pp);
    800024dc:	8526                	mv	a0,s1
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	680080e7          	jalr	1664(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800024e6:	8526                	mv	a0,s1
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	7a2080e7          	jalr	1954(ra) # 80000c8a <release>
          release(&wait_lock);
    800024f0:	0000e517          	auipc	a0,0xe
    800024f4:	68850513          	addi	a0,a0,1672 # 80010b78 <wait_lock>
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	792080e7          	jalr	1938(ra) # 80000c8a <release>
          return pid;
    80002500:	a0b5                	j	8000256c <wait+0x106>
            release(&pp->lock);
    80002502:	8526                	mv	a0,s1
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	786080e7          	jalr	1926(ra) # 80000c8a <release>
            release(&wait_lock);
    8000250c:	0000e517          	auipc	a0,0xe
    80002510:	66c50513          	addi	a0,a0,1644 # 80010b78 <wait_lock>
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	776080e7          	jalr	1910(ra) # 80000c8a <release>
            return -1;
    8000251c:	59fd                	li	s3,-1
    8000251e:	a0b9                	j	8000256c <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002520:	19048493          	addi	s1,s1,400
    80002524:	03348463          	beq	s1,s3,8000254c <wait+0xe6>
      if (pp->parent == p)
    80002528:	7c9c                	ld	a5,56(s1)
    8000252a:	ff279be3          	bne	a5,s2,80002520 <wait+0xba>
        acquire(&pp->lock);
    8000252e:	8526                	mv	a0,s1
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	6a6080e7          	jalr	1702(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002538:	4c9c                	lw	a5,24(s1)
    8000253a:	f94781e3          	beq	a5,s4,800024bc <wait+0x56>
        release(&pp->lock);
    8000253e:	8526                	mv	a0,s1
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	74a080e7          	jalr	1866(ra) # 80000c8a <release>
        havekids = 1;
    80002548:	8756                	mv	a4,s5
    8000254a:	bfd9                	j	80002520 <wait+0xba>
    if (!havekids || killed(p))
    8000254c:	c719                	beqz	a4,8000255a <wait+0xf4>
    8000254e:	854a                	mv	a0,s2
    80002550:	00000097          	auipc	ra,0x0
    80002554:	ee4080e7          	jalr	-284(ra) # 80002434 <killed>
    80002558:	c51d                	beqz	a0,80002586 <wait+0x120>
      release(&wait_lock);
    8000255a:	0000e517          	auipc	a0,0xe
    8000255e:	61e50513          	addi	a0,a0,1566 # 80010b78 <wait_lock>
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	728080e7          	jalr	1832(ra) # 80000c8a <release>
      return -1;
    8000256a:	59fd                	li	s3,-1
}
    8000256c:	854e                	mv	a0,s3
    8000256e:	60a6                	ld	ra,72(sp)
    80002570:	6406                	ld	s0,64(sp)
    80002572:	74e2                	ld	s1,56(sp)
    80002574:	7942                	ld	s2,48(sp)
    80002576:	79a2                	ld	s3,40(sp)
    80002578:	7a02                	ld	s4,32(sp)
    8000257a:	6ae2                	ld	s5,24(sp)
    8000257c:	6b42                	ld	s6,16(sp)
    8000257e:	6ba2                	ld	s7,8(sp)
    80002580:	6c02                	ld	s8,0(sp)
    80002582:	6161                	addi	sp,sp,80
    80002584:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002586:	85e2                	mv	a1,s8
    80002588:	854a                	mv	a0,s2
    8000258a:	00000097          	auipc	ra,0x0
    8000258e:	bf6080e7          	jalr	-1034(ra) # 80002180 <sleep>
    havekids = 0;
    80002592:	bf39                	j	800024b0 <wait+0x4a>

0000000080002594 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002594:	7179                	addi	sp,sp,-48
    80002596:	f406                	sd	ra,40(sp)
    80002598:	f022                	sd	s0,32(sp)
    8000259a:	ec26                	sd	s1,24(sp)
    8000259c:	e84a                	sd	s2,16(sp)
    8000259e:	e44e                	sd	s3,8(sp)
    800025a0:	e052                	sd	s4,0(sp)
    800025a2:	1800                	addi	s0,sp,48
    800025a4:	84aa                	mv	s1,a0
    800025a6:	892e                	mv	s2,a1
    800025a8:	89b2                	mv	s3,a2
    800025aa:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025ac:	fffff097          	auipc	ra,0xfffff
    800025b0:	400080e7          	jalr	1024(ra) # 800019ac <myproc>
  if (user_dst)
    800025b4:	c08d                	beqz	s1,800025d6 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800025b6:	86d2                	mv	a3,s4
    800025b8:	864e                	mv	a2,s3
    800025ba:	85ca                	mv	a1,s2
    800025bc:	6928                	ld	a0,80(a0)
    800025be:	fffff097          	auipc	ra,0xfffff
    800025c2:	0aa080e7          	jalr	170(ra) # 80001668 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025c6:	70a2                	ld	ra,40(sp)
    800025c8:	7402                	ld	s0,32(sp)
    800025ca:	64e2                	ld	s1,24(sp)
    800025cc:	6942                	ld	s2,16(sp)
    800025ce:	69a2                	ld	s3,8(sp)
    800025d0:	6a02                	ld	s4,0(sp)
    800025d2:	6145                	addi	sp,sp,48
    800025d4:	8082                	ret
    memmove((char *)dst, src, len);
    800025d6:	000a061b          	sext.w	a2,s4
    800025da:	85ce                	mv	a1,s3
    800025dc:	854a                	mv	a0,s2
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	750080e7          	jalr	1872(ra) # 80000d2e <memmove>
    return 0;
    800025e6:	8526                	mv	a0,s1
    800025e8:	bff9                	j	800025c6 <either_copyout+0x32>

00000000800025ea <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025ea:	7179                	addi	sp,sp,-48
    800025ec:	f406                	sd	ra,40(sp)
    800025ee:	f022                	sd	s0,32(sp)
    800025f0:	ec26                	sd	s1,24(sp)
    800025f2:	e84a                	sd	s2,16(sp)
    800025f4:	e44e                	sd	s3,8(sp)
    800025f6:	e052                	sd	s4,0(sp)
    800025f8:	1800                	addi	s0,sp,48
    800025fa:	892a                	mv	s2,a0
    800025fc:	84ae                	mv	s1,a1
    800025fe:	89b2                	mv	s3,a2
    80002600:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002602:	fffff097          	auipc	ra,0xfffff
    80002606:	3aa080e7          	jalr	938(ra) # 800019ac <myproc>
  if (user_src)
    8000260a:	c08d                	beqz	s1,8000262c <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000260c:	86d2                	mv	a3,s4
    8000260e:	864e                	mv	a2,s3
    80002610:	85ca                	mv	a1,s2
    80002612:	6928                	ld	a0,80(a0)
    80002614:	fffff097          	auipc	ra,0xfffff
    80002618:	0e0080e7          	jalr	224(ra) # 800016f4 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000261c:	70a2                	ld	ra,40(sp)
    8000261e:	7402                	ld	s0,32(sp)
    80002620:	64e2                	ld	s1,24(sp)
    80002622:	6942                	ld	s2,16(sp)
    80002624:	69a2                	ld	s3,8(sp)
    80002626:	6a02                	ld	s4,0(sp)
    80002628:	6145                	addi	sp,sp,48
    8000262a:	8082                	ret
    memmove(dst, (char *)src, len);
    8000262c:	000a061b          	sext.w	a2,s4
    80002630:	85ce                	mv	a1,s3
    80002632:	854a                	mv	a0,s2
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	6fa080e7          	jalr	1786(ra) # 80000d2e <memmove>
    return 0;
    8000263c:	8526                	mv	a0,s1
    8000263e:	bff9                	j	8000261c <either_copyin+0x32>

0000000080002640 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002640:	715d                	addi	sp,sp,-80
    80002642:	e486                	sd	ra,72(sp)
    80002644:	e0a2                	sd	s0,64(sp)
    80002646:	fc26                	sd	s1,56(sp)
    80002648:	f84a                	sd	s2,48(sp)
    8000264a:	f44e                	sd	s3,40(sp)
    8000264c:	f052                	sd	s4,32(sp)
    8000264e:	ec56                	sd	s5,24(sp)
    80002650:	e85a                	sd	s6,16(sp)
    80002652:	e45e                	sd	s7,8(sp)
    80002654:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002656:	00006517          	auipc	a0,0x6
    8000265a:	c4a50513          	addi	a0,a0,-950 # 800082a0 <digits+0x260>
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	f2a080e7          	jalr	-214(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002666:	0000f497          	auipc	s1,0xf
    8000266a:	a8248493          	addi	s1,s1,-1406 # 800110e8 <proc+0x158>
    8000266e:	00015917          	auipc	s2,0x15
    80002672:	e7a90913          	addi	s2,s2,-390 # 800174e8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002676:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002678:	00006997          	auipc	s3,0x6
    8000267c:	c0898993          	addi	s3,s3,-1016 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002680:	00006a97          	auipc	s5,0x6
    80002684:	c08a8a93          	addi	s5,s5,-1016 # 80008288 <digits+0x248>
    printf("\n");
    80002688:	00006a17          	auipc	s4,0x6
    8000268c:	c18a0a13          	addi	s4,s4,-1000 # 800082a0 <digits+0x260>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002690:	00006b97          	auipc	s7,0x6
    80002694:	c48b8b93          	addi	s7,s7,-952 # 800082d8 <states.0>
    80002698:	a00d                	j	800026ba <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000269a:	ed86a583          	lw	a1,-296(a3)
    8000269e:	8556                	mv	a0,s5
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	ee8080e7          	jalr	-280(ra) # 80000588 <printf>
    printf("\n");
    800026a8:	8552                	mv	a0,s4
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	ede080e7          	jalr	-290(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800026b2:	19048493          	addi	s1,s1,400
    800026b6:	03248163          	beq	s1,s2,800026d8 <procdump+0x98>
    if (p->state == UNUSED)
    800026ba:	86a6                	mv	a3,s1
    800026bc:	ec04a783          	lw	a5,-320(s1)
    800026c0:	dbed                	beqz	a5,800026b2 <procdump+0x72>
      state = "???";
    800026c2:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026c4:	fcfb6be3          	bltu	s6,a5,8000269a <procdump+0x5a>
    800026c8:	1782                	slli	a5,a5,0x20
    800026ca:	9381                	srli	a5,a5,0x20
    800026cc:	078e                	slli	a5,a5,0x3
    800026ce:	97de                	add	a5,a5,s7
    800026d0:	6390                	ld	a2,0(a5)
    800026d2:	f661                	bnez	a2,8000269a <procdump+0x5a>
      state = "???";
    800026d4:	864e                	mv	a2,s3
    800026d6:	b7d1                	j	8000269a <procdump+0x5a>
  }
}
    800026d8:	60a6                	ld	ra,72(sp)
    800026da:	6406                	ld	s0,64(sp)
    800026dc:	74e2                	ld	s1,56(sp)
    800026de:	7942                	ld	s2,48(sp)
    800026e0:	79a2                	ld	s3,40(sp)
    800026e2:	7a02                	ld	s4,32(sp)
    800026e4:	6ae2                	ld	s5,24(sp)
    800026e6:	6b42                	ld	s6,16(sp)
    800026e8:	6ba2                	ld	s7,8(sp)
    800026ea:	6161                	addi	sp,sp,80
    800026ec:	8082                	ret

00000000800026ee <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800026ee:	711d                	addi	sp,sp,-96
    800026f0:	ec86                	sd	ra,88(sp)
    800026f2:	e8a2                	sd	s0,80(sp)
    800026f4:	e4a6                	sd	s1,72(sp)
    800026f6:	e0ca                	sd	s2,64(sp)
    800026f8:	fc4e                	sd	s3,56(sp)
    800026fa:	f852                	sd	s4,48(sp)
    800026fc:	f456                	sd	s5,40(sp)
    800026fe:	f05a                	sd	s6,32(sp)
    80002700:	ec5e                	sd	s7,24(sp)
    80002702:	e862                	sd	s8,16(sp)
    80002704:	e466                	sd	s9,8(sp)
    80002706:	e06a                	sd	s10,0(sp)
    80002708:	1080                	addi	s0,sp,96
    8000270a:	8b2a                	mv	s6,a0
    8000270c:	8bae                	mv	s7,a1
    8000270e:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	29c080e7          	jalr	668(ra) # 800019ac <myproc>
    80002718:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000271a:	0000e517          	auipc	a0,0xe
    8000271e:	45e50513          	addi	a0,a0,1118 # 80010b78 <wait_lock>
    80002722:	ffffe097          	auipc	ra,0xffffe
    80002726:	4b4080e7          	jalr	1204(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000272a:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000272c:	4a15                	li	s4,5
        havekids = 1;
    8000272e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002730:	00015997          	auipc	s3,0x15
    80002734:	c6098993          	addi	s3,s3,-928 # 80017390 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002738:	0000ed17          	auipc	s10,0xe
    8000273c:	440d0d13          	addi	s10,s10,1088 # 80010b78 <wait_lock>
    havekids = 0;
    80002740:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002742:	0000f497          	auipc	s1,0xf
    80002746:	84e48493          	addi	s1,s1,-1970 # 80010f90 <proc>
    8000274a:	a059                	j	800027d0 <waitx+0xe2>
          pid = np->pid;
    8000274c:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002750:	1684a703          	lw	a4,360(s1)
    80002754:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002758:	16c4a783          	lw	a5,364(s1)
    8000275c:	9f3d                	addw	a4,a4,a5
    8000275e:	1704a783          	lw	a5,368(s1)
    80002762:	9f99                	subw	a5,a5,a4
    80002764:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002768:	000b0e63          	beqz	s6,80002784 <waitx+0x96>
    8000276c:	4691                	li	a3,4
    8000276e:	02c48613          	addi	a2,s1,44
    80002772:	85da                	mv	a1,s6
    80002774:	05093503          	ld	a0,80(s2)
    80002778:	fffff097          	auipc	ra,0xfffff
    8000277c:	ef0080e7          	jalr	-272(ra) # 80001668 <copyout>
    80002780:	02054563          	bltz	a0,800027aa <waitx+0xbc>
          freeproc(np);
    80002784:	8526                	mv	a0,s1
    80002786:	fffff097          	auipc	ra,0xfffff
    8000278a:	3d8080e7          	jalr	984(ra) # 80001b5e <freeproc>
          release(&np->lock);
    8000278e:	8526                	mv	a0,s1
    80002790:	ffffe097          	auipc	ra,0xffffe
    80002794:	4fa080e7          	jalr	1274(ra) # 80000c8a <release>
          release(&wait_lock);
    80002798:	0000e517          	auipc	a0,0xe
    8000279c:	3e050513          	addi	a0,a0,992 # 80010b78 <wait_lock>
    800027a0:	ffffe097          	auipc	ra,0xffffe
    800027a4:	4ea080e7          	jalr	1258(ra) # 80000c8a <release>
          return pid;
    800027a8:	a09d                	j	8000280e <waitx+0x120>
            release(&np->lock);
    800027aa:	8526                	mv	a0,s1
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	4de080e7          	jalr	1246(ra) # 80000c8a <release>
            release(&wait_lock);
    800027b4:	0000e517          	auipc	a0,0xe
    800027b8:	3c450513          	addi	a0,a0,964 # 80010b78 <wait_lock>
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	4ce080e7          	jalr	1230(ra) # 80000c8a <release>
            return -1;
    800027c4:	59fd                	li	s3,-1
    800027c6:	a0a1                	j	8000280e <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800027c8:	19048493          	addi	s1,s1,400
    800027cc:	03348463          	beq	s1,s3,800027f4 <waitx+0x106>
      if (np->parent == p)
    800027d0:	7c9c                	ld	a5,56(s1)
    800027d2:	ff279be3          	bne	a5,s2,800027c8 <waitx+0xda>
        acquire(&np->lock);
    800027d6:	8526                	mv	a0,s1
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	3fe080e7          	jalr	1022(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    800027e0:	4c9c                	lw	a5,24(s1)
    800027e2:	f74785e3          	beq	a5,s4,8000274c <waitx+0x5e>
        release(&np->lock);
    800027e6:	8526                	mv	a0,s1
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	4a2080e7          	jalr	1186(ra) # 80000c8a <release>
        havekids = 1;
    800027f0:	8756                	mv	a4,s5
    800027f2:	bfd9                	j	800027c8 <waitx+0xda>
    if (!havekids || p->killed)
    800027f4:	c701                	beqz	a4,800027fc <waitx+0x10e>
    800027f6:	02892783          	lw	a5,40(s2)
    800027fa:	cb8d                	beqz	a5,8000282c <waitx+0x13e>
      release(&wait_lock);
    800027fc:	0000e517          	auipc	a0,0xe
    80002800:	37c50513          	addi	a0,a0,892 # 80010b78 <wait_lock>
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	486080e7          	jalr	1158(ra) # 80000c8a <release>
      return -1;
    8000280c:	59fd                	li	s3,-1
  }
}
    8000280e:	854e                	mv	a0,s3
    80002810:	60e6                	ld	ra,88(sp)
    80002812:	6446                	ld	s0,80(sp)
    80002814:	64a6                	ld	s1,72(sp)
    80002816:	6906                	ld	s2,64(sp)
    80002818:	79e2                	ld	s3,56(sp)
    8000281a:	7a42                	ld	s4,48(sp)
    8000281c:	7aa2                	ld	s5,40(sp)
    8000281e:	7b02                	ld	s6,32(sp)
    80002820:	6be2                	ld	s7,24(sp)
    80002822:	6c42                	ld	s8,16(sp)
    80002824:	6ca2                	ld	s9,8(sp)
    80002826:	6d02                	ld	s10,0(sp)
    80002828:	6125                	addi	sp,sp,96
    8000282a:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000282c:	85ea                	mv	a1,s10
    8000282e:	854a                	mv	a0,s2
    80002830:	00000097          	auipc	ra,0x0
    80002834:	950080e7          	jalr	-1712(ra) # 80002180 <sleep>
    havekids = 0;
    80002838:	b721                	j	80002740 <waitx+0x52>

000000008000283a <update_time>:

void update_time()
{
    8000283a:	715d                	addi	sp,sp,-80
    8000283c:	e486                	sd	ra,72(sp)
    8000283e:	e0a2                	sd	s0,64(sp)
    80002840:	fc26                	sd	s1,56(sp)
    80002842:	f84a                	sd	s2,48(sp)
    80002844:	f44e                	sd	s3,40(sp)
    80002846:	f052                	sd	s4,32(sp)
    80002848:	ec56                	sd	s5,24(sp)
    8000284a:	e85a                	sd	s6,16(sp)
    8000284c:	e45e                	sd	s7,8(sp)
    8000284e:	0880                	addi	s0,sp,80
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002850:	0000e497          	auipc	s1,0xe
    80002854:	74048493          	addi	s1,s1,1856 # 80010f90 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002858:	4a11                	li	s4,4
    {
      p->rtime++;
      p->RTime++;
    }
    else if (p->state == SLEEPING)
    8000285a:	4909                	li	s2,2
    {
      p->STime++;
    }
    else if (p->state == RUNNABLE)
    8000285c:	4a8d                	li	s5,3
    {
      p->WTime++;
    }
    if (p->pid >= 3)
    {
      printf("%d,%d,%d\n", p->pid, ticks, p->DP);
    8000285e:	00006b97          	auipc	s7,0x6
    80002862:	092b8b93          	addi	s7,s7,146 # 800088f0 <ticks>
    80002866:	00006b17          	auipc	s6,0x6
    8000286a:	a32b0b13          	addi	s6,s6,-1486 # 80008298 <digits+0x258>
  for (p = proc; p < &proc[NPROC]; p++)
    8000286e:	00015997          	auipc	s3,0x15
    80002872:	b2298993          	addi	s3,s3,-1246 # 80017390 <tickslock>
    80002876:	a03d                	j	800028a4 <update_time+0x6a>
      p->rtime++;
    80002878:	1684a783          	lw	a5,360(s1)
    8000287c:	2785                	addiw	a5,a5,1
    8000287e:	16f4a423          	sw	a5,360(s1)
      p->RTime++;
    80002882:	1784a783          	lw	a5,376(s1)
    80002886:	2785                	addiw	a5,a5,1
    80002888:	16f4ac23          	sw	a5,376(s1)
    if (p->pid >= 3)
    8000288c:	588c                	lw	a1,48(s1)
    8000288e:	04b94363          	blt	s2,a1,800028d4 <update_time+0x9a>

      // printf("PID : %d, Priority : %d\n", p->pid, p->DP);
    }
    release(&p->lock);
    80002892:	8526                	mv	a0,s1
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	3f6080e7          	jalr	1014(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000289c:	19048493          	addi	s1,s1,400
    800028a0:	05348463          	beq	s1,s3,800028e8 <update_time+0xae>
    acquire(&p->lock);
    800028a4:	8526                	mv	a0,s1
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	330080e7          	jalr	816(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    800028ae:	4c9c                	lw	a5,24(s1)
    800028b0:	fd4784e3          	beq	a5,s4,80002878 <update_time+0x3e>
    else if (p->state == SLEEPING)
    800028b4:	01278a63          	beq	a5,s2,800028c8 <update_time+0x8e>
    else if (p->state == RUNNABLE)
    800028b8:	fd579ae3          	bne	a5,s5,8000288c <update_time+0x52>
      p->WTime++;
    800028bc:	17c4a783          	lw	a5,380(s1)
    800028c0:	2785                	addiw	a5,a5,1
    800028c2:	16f4ae23          	sw	a5,380(s1)
    800028c6:	b7d9                	j	8000288c <update_time+0x52>
      p->STime++;
    800028c8:	1744a783          	lw	a5,372(s1)
    800028cc:	2785                	addiw	a5,a5,1
    800028ce:	16f4aa23          	sw	a5,372(s1)
    800028d2:	bf6d                	j	8000288c <update_time+0x52>
      printf("%d,%d,%d\n", p->pid, ticks, p->DP);
    800028d4:	1884a683          	lw	a3,392(s1)
    800028d8:	000ba603          	lw	a2,0(s7)
    800028dc:	855a                	mv	a0,s6
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	caa080e7          	jalr	-854(ra) # 80000588 <printf>
    800028e6:	b775                	j	80002892 <update_time+0x58>
  }
    800028e8:	60a6                	ld	ra,72(sp)
    800028ea:	6406                	ld	s0,64(sp)
    800028ec:	74e2                	ld	s1,56(sp)
    800028ee:	7942                	ld	s2,48(sp)
    800028f0:	79a2                	ld	s3,40(sp)
    800028f2:	7a02                	ld	s4,32(sp)
    800028f4:	6ae2                	ld	s5,24(sp)
    800028f6:	6b42                	ld	s6,16(sp)
    800028f8:	6ba2                	ld	s7,8(sp)
    800028fa:	6161                	addi	sp,sp,80
    800028fc:	8082                	ret

00000000800028fe <swtch>:
    800028fe:	00153023          	sd	ra,0(a0)
    80002902:	00253423          	sd	sp,8(a0)
    80002906:	e900                	sd	s0,16(a0)
    80002908:	ed04                	sd	s1,24(a0)
    8000290a:	03253023          	sd	s2,32(a0)
    8000290e:	03353423          	sd	s3,40(a0)
    80002912:	03453823          	sd	s4,48(a0)
    80002916:	03553c23          	sd	s5,56(a0)
    8000291a:	05653023          	sd	s6,64(a0)
    8000291e:	05753423          	sd	s7,72(a0)
    80002922:	05853823          	sd	s8,80(a0)
    80002926:	05953c23          	sd	s9,88(a0)
    8000292a:	07a53023          	sd	s10,96(a0)
    8000292e:	07b53423          	sd	s11,104(a0)
    80002932:	0005b083          	ld	ra,0(a1)
    80002936:	0085b103          	ld	sp,8(a1)
    8000293a:	6980                	ld	s0,16(a1)
    8000293c:	6d84                	ld	s1,24(a1)
    8000293e:	0205b903          	ld	s2,32(a1)
    80002942:	0285b983          	ld	s3,40(a1)
    80002946:	0305ba03          	ld	s4,48(a1)
    8000294a:	0385ba83          	ld	s5,56(a1)
    8000294e:	0405bb03          	ld	s6,64(a1)
    80002952:	0485bb83          	ld	s7,72(a1)
    80002956:	0505bc03          	ld	s8,80(a1)
    8000295a:	0585bc83          	ld	s9,88(a1)
    8000295e:	0605bd03          	ld	s10,96(a1)
    80002962:	0685bd83          	ld	s11,104(a1)
    80002966:	8082                	ret

0000000080002968 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002968:	1141                	addi	sp,sp,-16
    8000296a:	e406                	sd	ra,8(sp)
    8000296c:	e022                	sd	s0,0(sp)
    8000296e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002970:	00006597          	auipc	a1,0x6
    80002974:	99858593          	addi	a1,a1,-1640 # 80008308 <states.0+0x30>
    80002978:	00015517          	auipc	a0,0x15
    8000297c:	a1850513          	addi	a0,a0,-1512 # 80017390 <tickslock>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	1c6080e7          	jalr	454(ra) # 80000b46 <initlock>
}
    80002988:	60a2                	ld	ra,8(sp)
    8000298a:	6402                	ld	s0,0(sp)
    8000298c:	0141                	addi	sp,sp,16
    8000298e:	8082                	ret

0000000080002990 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002990:	1141                	addi	sp,sp,-16
    80002992:	e422                	sd	s0,8(sp)
    80002994:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002996:	00003797          	auipc	a5,0x3
    8000299a:	64a78793          	addi	a5,a5,1610 # 80005fe0 <kernelvec>
    8000299e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029a2:	6422                	ld	s0,8(sp)
    800029a4:	0141                	addi	sp,sp,16
    800029a6:	8082                	ret

00000000800029a8 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    800029a8:	1141                	addi	sp,sp,-16
    800029aa:	e406                	sd	ra,8(sp)
    800029ac:	e022                	sd	s0,0(sp)
    800029ae:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029b0:	fffff097          	auipc	ra,0xfffff
    800029b4:	ffc080e7          	jalr	-4(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029bc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029be:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800029c2:	00004617          	auipc	a2,0x4
    800029c6:	63e60613          	addi	a2,a2,1598 # 80007000 <_trampoline>
    800029ca:	00004697          	auipc	a3,0x4
    800029ce:	63668693          	addi	a3,a3,1590 # 80007000 <_trampoline>
    800029d2:	8e91                	sub	a3,a3,a2
    800029d4:	040007b7          	lui	a5,0x4000
    800029d8:	17fd                	addi	a5,a5,-1
    800029da:	07b2                	slli	a5,a5,0xc
    800029dc:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029de:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029e2:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029e4:	180026f3          	csrr	a3,satp
    800029e8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029ea:	6d38                	ld	a4,88(a0)
    800029ec:	6134                	ld	a3,64(a0)
    800029ee:	6585                	lui	a1,0x1
    800029f0:	96ae                	add	a3,a3,a1
    800029f2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029f4:	6d38                	ld	a4,88(a0)
    800029f6:	00000697          	auipc	a3,0x0
    800029fa:	13e68693          	addi	a3,a3,318 # 80002b34 <usertrap>
    800029fe:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002a00:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a02:	8692                	mv	a3,tp
    80002a04:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a06:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a0a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a0e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a12:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a16:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a18:	6f18                	ld	a4,24(a4)
    80002a1a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a1e:	6928                	ld	a0,80(a0)
    80002a20:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a22:	00004717          	auipc	a4,0x4
    80002a26:	67a70713          	addi	a4,a4,1658 # 8000709c <userret>
    80002a2a:	8f11                	sub	a4,a4,a2
    80002a2c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a2e:	577d                	li	a4,-1
    80002a30:	177e                	slli	a4,a4,0x3f
    80002a32:	8d59                	or	a0,a0,a4
    80002a34:	9782                	jalr	a5
}
    80002a36:	60a2                	ld	ra,8(sp)
    80002a38:	6402                	ld	s0,0(sp)
    80002a3a:	0141                	addi	sp,sp,16
    80002a3c:	8082                	ret

0000000080002a3e <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002a3e:	1101                	addi	sp,sp,-32
    80002a40:	ec06                	sd	ra,24(sp)
    80002a42:	e822                	sd	s0,16(sp)
    80002a44:	e426                	sd	s1,8(sp)
    80002a46:	e04a                	sd	s2,0(sp)
    80002a48:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a4a:	00015917          	auipc	s2,0x15
    80002a4e:	94690913          	addi	s2,s2,-1722 # 80017390 <tickslock>
    80002a52:	854a                	mv	a0,s2
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	182080e7          	jalr	386(ra) # 80000bd6 <acquire>
  ticks++;
    80002a5c:	00006497          	auipc	s1,0x6
    80002a60:	e9448493          	addi	s1,s1,-364 # 800088f0 <ticks>
    80002a64:	409c                	lw	a5,0(s1)
    80002a66:	2785                	addiw	a5,a5,1
    80002a68:	c09c                	sw	a5,0(s1)
  update_time();
    80002a6a:	00000097          	auipc	ra,0x0
    80002a6e:	dd0080e7          	jalr	-560(ra) # 8000283a <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002a72:	8526                	mv	a0,s1
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	770080e7          	jalr	1904(ra) # 800021e4 <wakeup>
  release(&tickslock);
    80002a7c:	854a                	mv	a0,s2
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	20c080e7          	jalr	524(ra) # 80000c8a <release>
}
    80002a86:	60e2                	ld	ra,24(sp)
    80002a88:	6442                	ld	s0,16(sp)
    80002a8a:	64a2                	ld	s1,8(sp)
    80002a8c:	6902                	ld	s2,0(sp)
    80002a8e:	6105                	addi	sp,sp,32
    80002a90:	8082                	ret

0000000080002a92 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002a92:	1101                	addi	sp,sp,-32
    80002a94:	ec06                	sd	ra,24(sp)
    80002a96:	e822                	sd	s0,16(sp)
    80002a98:	e426                	sd	s1,8(sp)
    80002a9a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a9c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002aa0:	00074d63          	bltz	a4,80002aba <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002aa4:	57fd                	li	a5,-1
    80002aa6:	17fe                	slli	a5,a5,0x3f
    80002aa8:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002aaa:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002aac:	06f70363          	beq	a4,a5,80002b12 <devintr+0x80>
  }
}
    80002ab0:	60e2                	ld	ra,24(sp)
    80002ab2:	6442                	ld	s0,16(sp)
    80002ab4:	64a2                	ld	s1,8(sp)
    80002ab6:	6105                	addi	sp,sp,32
    80002ab8:	8082                	ret
      (scause & 0xff) == 9)
    80002aba:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002abe:	46a5                	li	a3,9
    80002ac0:	fed792e3          	bne	a5,a3,80002aa4 <devintr+0x12>
    int irq = plic_claim();
    80002ac4:	00003097          	auipc	ra,0x3
    80002ac8:	624080e7          	jalr	1572(ra) # 800060e8 <plic_claim>
    80002acc:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002ace:	47a9                	li	a5,10
    80002ad0:	02f50763          	beq	a0,a5,80002afe <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002ad4:	4785                	li	a5,1
    80002ad6:	02f50963          	beq	a0,a5,80002b08 <devintr+0x76>
    return 1;
    80002ada:	4505                	li	a0,1
    else if (irq)
    80002adc:	d8f1                	beqz	s1,80002ab0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ade:	85a6                	mv	a1,s1
    80002ae0:	00006517          	auipc	a0,0x6
    80002ae4:	83050513          	addi	a0,a0,-2000 # 80008310 <states.0+0x38>
    80002ae8:	ffffe097          	auipc	ra,0xffffe
    80002aec:	aa0080e7          	jalr	-1376(ra) # 80000588 <printf>
      plic_complete(irq);
    80002af0:	8526                	mv	a0,s1
    80002af2:	00003097          	auipc	ra,0x3
    80002af6:	61a080e7          	jalr	1562(ra) # 8000610c <plic_complete>
    return 1;
    80002afa:	4505                	li	a0,1
    80002afc:	bf55                	j	80002ab0 <devintr+0x1e>
      uartintr();
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	e9c080e7          	jalr	-356(ra) # 8000099a <uartintr>
    80002b06:	b7ed                	j	80002af0 <devintr+0x5e>
      virtio_disk_intr();
    80002b08:	00004097          	auipc	ra,0x4
    80002b0c:	ad0080e7          	jalr	-1328(ra) # 800065d8 <virtio_disk_intr>
    80002b10:	b7c5                	j	80002af0 <devintr+0x5e>
    if (cpuid() == 0)
    80002b12:	fffff097          	auipc	ra,0xfffff
    80002b16:	e6e080e7          	jalr	-402(ra) # 80001980 <cpuid>
    80002b1a:	c901                	beqz	a0,80002b2a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b1c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b20:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b22:	14479073          	csrw	sip,a5
    return 2;
    80002b26:	4509                	li	a0,2
    80002b28:	b761                	j	80002ab0 <devintr+0x1e>
      clockintr();
    80002b2a:	00000097          	auipc	ra,0x0
    80002b2e:	f14080e7          	jalr	-236(ra) # 80002a3e <clockintr>
    80002b32:	b7ed                	j	80002b1c <devintr+0x8a>

0000000080002b34 <usertrap>:
{
    80002b34:	1101                	addi	sp,sp,-32
    80002b36:	ec06                	sd	ra,24(sp)
    80002b38:	e822                	sd	s0,16(sp)
    80002b3a:	e426                	sd	s1,8(sp)
    80002b3c:	e04a                	sd	s2,0(sp)
    80002b3e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b40:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002b44:	1007f793          	andi	a5,a5,256
    80002b48:	e3b1                	bnez	a5,80002b8c <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b4a:	00003797          	auipc	a5,0x3
    80002b4e:	49678793          	addi	a5,a5,1174 # 80005fe0 <kernelvec>
    80002b52:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	e56080e7          	jalr	-426(ra) # 800019ac <myproc>
    80002b5e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b60:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b62:	14102773          	csrr	a4,sepc
    80002b66:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b68:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002b6c:	47a1                	li	a5,8
    80002b6e:	02f70763          	beq	a4,a5,80002b9c <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002b72:	00000097          	auipc	ra,0x0
    80002b76:	f20080e7          	jalr	-224(ra) # 80002a92 <devintr>
    80002b7a:	892a                	mv	s2,a0
    80002b7c:	c151                	beqz	a0,80002c00 <usertrap+0xcc>
  if (killed(p))
    80002b7e:	8526                	mv	a0,s1
    80002b80:	00000097          	auipc	ra,0x0
    80002b84:	8b4080e7          	jalr	-1868(ra) # 80002434 <killed>
    80002b88:	c929                	beqz	a0,80002bda <usertrap+0xa6>
    80002b8a:	a099                	j	80002bd0 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002b8c:	00005517          	auipc	a0,0x5
    80002b90:	7a450513          	addi	a0,a0,1956 # 80008330 <states.0+0x58>
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	9aa080e7          	jalr	-1622(ra) # 8000053e <panic>
    if (killed(p))
    80002b9c:	00000097          	auipc	ra,0x0
    80002ba0:	898080e7          	jalr	-1896(ra) # 80002434 <killed>
    80002ba4:	e921                	bnez	a0,80002bf4 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002ba6:	6cb8                	ld	a4,88(s1)
    80002ba8:	6f1c                	ld	a5,24(a4)
    80002baa:	0791                	addi	a5,a5,4
    80002bac:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bb2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bb6:	10079073          	csrw	sstatus,a5
    syscall();
    80002bba:	00000097          	auipc	ra,0x0
    80002bbe:	2d4080e7          	jalr	724(ra) # 80002e8e <syscall>
  if (killed(p))
    80002bc2:	8526                	mv	a0,s1
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	870080e7          	jalr	-1936(ra) # 80002434 <killed>
    80002bcc:	c911                	beqz	a0,80002be0 <usertrap+0xac>
    80002bce:	4901                	li	s2,0
    exit(-1);
    80002bd0:	557d                	li	a0,-1
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	6e2080e7          	jalr	1762(ra) # 800022b4 <exit>
  if (which_dev == 2)
    80002bda:	4789                	li	a5,2
    80002bdc:	04f90f63          	beq	s2,a5,80002c3a <usertrap+0x106>
  usertrapret();
    80002be0:	00000097          	auipc	ra,0x0
    80002be4:	dc8080e7          	jalr	-568(ra) # 800029a8 <usertrapret>
}
    80002be8:	60e2                	ld	ra,24(sp)
    80002bea:	6442                	ld	s0,16(sp)
    80002bec:	64a2                	ld	s1,8(sp)
    80002bee:	6902                	ld	s2,0(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret
      exit(-1);
    80002bf4:	557d                	li	a0,-1
    80002bf6:	fffff097          	auipc	ra,0xfffff
    80002bfa:	6be080e7          	jalr	1726(ra) # 800022b4 <exit>
    80002bfe:	b765                	j	80002ba6 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c00:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c04:	5890                	lw	a2,48(s1)
    80002c06:	00005517          	auipc	a0,0x5
    80002c0a:	74a50513          	addi	a0,a0,1866 # 80008350 <states.0+0x78>
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	97a080e7          	jalr	-1670(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c16:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c1a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c1e:	00005517          	auipc	a0,0x5
    80002c22:	76250513          	addi	a0,a0,1890 # 80008380 <states.0+0xa8>
    80002c26:	ffffe097          	auipc	ra,0xffffe
    80002c2a:	962080e7          	jalr	-1694(ra) # 80000588 <printf>
    setkilled(p);
    80002c2e:	8526                	mv	a0,s1
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	7d8080e7          	jalr	2008(ra) # 80002408 <setkilled>
    80002c38:	b769                	j	80002bc2 <usertrap+0x8e>
    yield();
    80002c3a:	fffff097          	auipc	ra,0xfffff
    80002c3e:	50a080e7          	jalr	1290(ra) # 80002144 <yield>
    80002c42:	bf79                	j	80002be0 <usertrap+0xac>

0000000080002c44 <kerneltrap>:
{
    80002c44:	7179                	addi	sp,sp,-48
    80002c46:	f406                	sd	ra,40(sp)
    80002c48:	f022                	sd	s0,32(sp)
    80002c4a:	ec26                	sd	s1,24(sp)
    80002c4c:	e84a                	sd	s2,16(sp)
    80002c4e:	e44e                	sd	s3,8(sp)
    80002c50:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c52:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c56:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c5a:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002c5e:	1004f793          	andi	a5,s1,256
    80002c62:	cb85                	beqz	a5,80002c92 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c64:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c68:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002c6a:	ef85                	bnez	a5,80002ca2 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002c6c:	00000097          	auipc	ra,0x0
    80002c70:	e26080e7          	jalr	-474(ra) # 80002a92 <devintr>
    80002c74:	cd1d                	beqz	a0,80002cb2 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c76:	4789                	li	a5,2
    80002c78:	06f50a63          	beq	a0,a5,80002cec <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c7c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c80:	10049073          	csrw	sstatus,s1
}
    80002c84:	70a2                	ld	ra,40(sp)
    80002c86:	7402                	ld	s0,32(sp)
    80002c88:	64e2                	ld	s1,24(sp)
    80002c8a:	6942                	ld	s2,16(sp)
    80002c8c:	69a2                	ld	s3,8(sp)
    80002c8e:	6145                	addi	sp,sp,48
    80002c90:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c92:	00005517          	auipc	a0,0x5
    80002c96:	70e50513          	addi	a0,a0,1806 # 800083a0 <states.0+0xc8>
    80002c9a:	ffffe097          	auipc	ra,0xffffe
    80002c9e:	8a4080e7          	jalr	-1884(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ca2:	00005517          	auipc	a0,0x5
    80002ca6:	72650513          	addi	a0,a0,1830 # 800083c8 <states.0+0xf0>
    80002caa:	ffffe097          	auipc	ra,0xffffe
    80002cae:	894080e7          	jalr	-1900(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002cb2:	85ce                	mv	a1,s3
    80002cb4:	00005517          	auipc	a0,0x5
    80002cb8:	73450513          	addi	a0,a0,1844 # 800083e8 <states.0+0x110>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	8cc080e7          	jalr	-1844(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cc4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cc8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ccc:	00005517          	auipc	a0,0x5
    80002cd0:	72c50513          	addi	a0,a0,1836 # 800083f8 <states.0+0x120>
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	8b4080e7          	jalr	-1868(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002cdc:	00005517          	auipc	a0,0x5
    80002ce0:	73450513          	addi	a0,a0,1844 # 80008410 <states.0+0x138>
    80002ce4:	ffffe097          	auipc	ra,0xffffe
    80002ce8:	85a080e7          	jalr	-1958(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	cc0080e7          	jalr	-832(ra) # 800019ac <myproc>
    80002cf4:	d541                	beqz	a0,80002c7c <kerneltrap+0x38>
    80002cf6:	fffff097          	auipc	ra,0xfffff
    80002cfa:	cb6080e7          	jalr	-842(ra) # 800019ac <myproc>
    80002cfe:	4d18                	lw	a4,24(a0)
    80002d00:	4791                	li	a5,4
    80002d02:	f6f71de3          	bne	a4,a5,80002c7c <kerneltrap+0x38>
    yield();
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	43e080e7          	jalr	1086(ra) # 80002144 <yield>
    80002d0e:	b7bd                	j	80002c7c <kerneltrap+0x38>

0000000080002d10 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d10:	1101                	addi	sp,sp,-32
    80002d12:	ec06                	sd	ra,24(sp)
    80002d14:	e822                	sd	s0,16(sp)
    80002d16:	e426                	sd	s1,8(sp)
    80002d18:	1000                	addi	s0,sp,32
    80002d1a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	c90080e7          	jalr	-880(ra) # 800019ac <myproc>
  switch (n) {
    80002d24:	4795                	li	a5,5
    80002d26:	0497e163          	bltu	a5,s1,80002d68 <argraw+0x58>
    80002d2a:	048a                	slli	s1,s1,0x2
    80002d2c:	00005717          	auipc	a4,0x5
    80002d30:	71c70713          	addi	a4,a4,1820 # 80008448 <states.0+0x170>
    80002d34:	94ba                	add	s1,s1,a4
    80002d36:	409c                	lw	a5,0(s1)
    80002d38:	97ba                	add	a5,a5,a4
    80002d3a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d3c:	6d3c                	ld	a5,88(a0)
    80002d3e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d40:	60e2                	ld	ra,24(sp)
    80002d42:	6442                	ld	s0,16(sp)
    80002d44:	64a2                	ld	s1,8(sp)
    80002d46:	6105                	addi	sp,sp,32
    80002d48:	8082                	ret
    return p->trapframe->a1;
    80002d4a:	6d3c                	ld	a5,88(a0)
    80002d4c:	7fa8                	ld	a0,120(a5)
    80002d4e:	bfcd                	j	80002d40 <argraw+0x30>
    return p->trapframe->a2;
    80002d50:	6d3c                	ld	a5,88(a0)
    80002d52:	63c8                	ld	a0,128(a5)
    80002d54:	b7f5                	j	80002d40 <argraw+0x30>
    return p->trapframe->a3;
    80002d56:	6d3c                	ld	a5,88(a0)
    80002d58:	67c8                	ld	a0,136(a5)
    80002d5a:	b7dd                	j	80002d40 <argraw+0x30>
    return p->trapframe->a4;
    80002d5c:	6d3c                	ld	a5,88(a0)
    80002d5e:	6bc8                	ld	a0,144(a5)
    80002d60:	b7c5                	j	80002d40 <argraw+0x30>
    return p->trapframe->a5;
    80002d62:	6d3c                	ld	a5,88(a0)
    80002d64:	6fc8                	ld	a0,152(a5)
    80002d66:	bfe9                	j	80002d40 <argraw+0x30>
  panic("argraw");
    80002d68:	00005517          	auipc	a0,0x5
    80002d6c:	6b850513          	addi	a0,a0,1720 # 80008420 <states.0+0x148>
    80002d70:	ffffd097          	auipc	ra,0xffffd
    80002d74:	7ce080e7          	jalr	1998(ra) # 8000053e <panic>

0000000080002d78 <fetchaddr>:
{
    80002d78:	1101                	addi	sp,sp,-32
    80002d7a:	ec06                	sd	ra,24(sp)
    80002d7c:	e822                	sd	s0,16(sp)
    80002d7e:	e426                	sd	s1,8(sp)
    80002d80:	e04a                	sd	s2,0(sp)
    80002d82:	1000                	addi	s0,sp,32
    80002d84:	84aa                	mv	s1,a0
    80002d86:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	c24080e7          	jalr	-988(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d90:	653c                	ld	a5,72(a0)
    80002d92:	02f4f863          	bgeu	s1,a5,80002dc2 <fetchaddr+0x4a>
    80002d96:	00848713          	addi	a4,s1,8
    80002d9a:	02e7e663          	bltu	a5,a4,80002dc6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d9e:	46a1                	li	a3,8
    80002da0:	8626                	mv	a2,s1
    80002da2:	85ca                	mv	a1,s2
    80002da4:	6928                	ld	a0,80(a0)
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	94e080e7          	jalr	-1714(ra) # 800016f4 <copyin>
    80002dae:	00a03533          	snez	a0,a0
    80002db2:	40a00533          	neg	a0,a0
}
    80002db6:	60e2                	ld	ra,24(sp)
    80002db8:	6442                	ld	s0,16(sp)
    80002dba:	64a2                	ld	s1,8(sp)
    80002dbc:	6902                	ld	s2,0(sp)
    80002dbe:	6105                	addi	sp,sp,32
    80002dc0:	8082                	ret
    return -1;
    80002dc2:	557d                	li	a0,-1
    80002dc4:	bfcd                	j	80002db6 <fetchaddr+0x3e>
    80002dc6:	557d                	li	a0,-1
    80002dc8:	b7fd                	j	80002db6 <fetchaddr+0x3e>

0000000080002dca <fetchstr>:
{
    80002dca:	7179                	addi	sp,sp,-48
    80002dcc:	f406                	sd	ra,40(sp)
    80002dce:	f022                	sd	s0,32(sp)
    80002dd0:	ec26                	sd	s1,24(sp)
    80002dd2:	e84a                	sd	s2,16(sp)
    80002dd4:	e44e                	sd	s3,8(sp)
    80002dd6:	1800                	addi	s0,sp,48
    80002dd8:	892a                	mv	s2,a0
    80002dda:	84ae                	mv	s1,a1
    80002ddc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dde:	fffff097          	auipc	ra,0xfffff
    80002de2:	bce080e7          	jalr	-1074(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002de6:	86ce                	mv	a3,s3
    80002de8:	864a                	mv	a2,s2
    80002dea:	85a6                	mv	a1,s1
    80002dec:	6928                	ld	a0,80(a0)
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	994080e7          	jalr	-1644(ra) # 80001782 <copyinstr>
    80002df6:	00054e63          	bltz	a0,80002e12 <fetchstr+0x48>
  return strlen(buf);
    80002dfa:	8526                	mv	a0,s1
    80002dfc:	ffffe097          	auipc	ra,0xffffe
    80002e00:	052080e7          	jalr	82(ra) # 80000e4e <strlen>
}
    80002e04:	70a2                	ld	ra,40(sp)
    80002e06:	7402                	ld	s0,32(sp)
    80002e08:	64e2                	ld	s1,24(sp)
    80002e0a:	6942                	ld	s2,16(sp)
    80002e0c:	69a2                	ld	s3,8(sp)
    80002e0e:	6145                	addi	sp,sp,48
    80002e10:	8082                	ret
    return -1;
    80002e12:	557d                	li	a0,-1
    80002e14:	bfc5                	j	80002e04 <fetchstr+0x3a>

0000000080002e16 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002e16:	1101                	addi	sp,sp,-32
    80002e18:	ec06                	sd	ra,24(sp)
    80002e1a:	e822                	sd	s0,16(sp)
    80002e1c:	e426                	sd	s1,8(sp)
    80002e1e:	1000                	addi	s0,sp,32
    80002e20:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	eee080e7          	jalr	-274(ra) # 80002d10 <argraw>
    80002e2a:	c088                	sw	a0,0(s1)
}
    80002e2c:	60e2                	ld	ra,24(sp)
    80002e2e:	6442                	ld	s0,16(sp)
    80002e30:	64a2                	ld	s1,8(sp)
    80002e32:	6105                	addi	sp,sp,32
    80002e34:	8082                	ret

0000000080002e36 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002e36:	1101                	addi	sp,sp,-32
    80002e38:	ec06                	sd	ra,24(sp)
    80002e3a:	e822                	sd	s0,16(sp)
    80002e3c:	e426                	sd	s1,8(sp)
    80002e3e:	1000                	addi	s0,sp,32
    80002e40:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e42:	00000097          	auipc	ra,0x0
    80002e46:	ece080e7          	jalr	-306(ra) # 80002d10 <argraw>
    80002e4a:	e088                	sd	a0,0(s1)
}
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	64a2                	ld	s1,8(sp)
    80002e52:	6105                	addi	sp,sp,32
    80002e54:	8082                	ret

0000000080002e56 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e56:	7179                	addi	sp,sp,-48
    80002e58:	f406                	sd	ra,40(sp)
    80002e5a:	f022                	sd	s0,32(sp)
    80002e5c:	ec26                	sd	s1,24(sp)
    80002e5e:	e84a                	sd	s2,16(sp)
    80002e60:	1800                	addi	s0,sp,48
    80002e62:	84ae                	mv	s1,a1
    80002e64:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002e66:	fd840593          	addi	a1,s0,-40
    80002e6a:	00000097          	auipc	ra,0x0
    80002e6e:	fcc080e7          	jalr	-52(ra) # 80002e36 <argaddr>
  return fetchstr(addr, buf, max);
    80002e72:	864a                	mv	a2,s2
    80002e74:	85a6                	mv	a1,s1
    80002e76:	fd843503          	ld	a0,-40(s0)
    80002e7a:	00000097          	auipc	ra,0x0
    80002e7e:	f50080e7          	jalr	-176(ra) # 80002dca <fetchstr>
}
    80002e82:	70a2                	ld	ra,40(sp)
    80002e84:	7402                	ld	s0,32(sp)
    80002e86:	64e2                	ld	s1,24(sp)
    80002e88:	6942                	ld	s2,16(sp)
    80002e8a:	6145                	addi	sp,sp,48
    80002e8c:	8082                	ret

0000000080002e8e <syscall>:
[SYS_set_priority] sys_set_priority,
};

void
syscall(void)
{
    80002e8e:	1101                	addi	sp,sp,-32
    80002e90:	ec06                	sd	ra,24(sp)
    80002e92:	e822                	sd	s0,16(sp)
    80002e94:	e426                	sd	s1,8(sp)
    80002e96:	e04a                	sd	s2,0(sp)
    80002e98:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e9a:	fffff097          	auipc	ra,0xfffff
    80002e9e:	b12080e7          	jalr	-1262(ra) # 800019ac <myproc>
    80002ea2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ea4:	05853903          	ld	s2,88(a0)
    80002ea8:	0a893783          	ld	a5,168(s2)
    80002eac:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002eb0:	37fd                	addiw	a5,a5,-1
    80002eb2:	475d                	li	a4,23
    80002eb4:	00f76f63          	bltu	a4,a5,80002ed2 <syscall+0x44>
    80002eb8:	00369713          	slli	a4,a3,0x3
    80002ebc:	00005797          	auipc	a5,0x5
    80002ec0:	5a478793          	addi	a5,a5,1444 # 80008460 <syscalls>
    80002ec4:	97ba                	add	a5,a5,a4
    80002ec6:	639c                	ld	a5,0(a5)
    80002ec8:	c789                	beqz	a5,80002ed2 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002eca:	9782                	jalr	a5
    80002ecc:	06a93823          	sd	a0,112(s2)
    80002ed0:	a839                	j	80002eee <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ed2:	15848613          	addi	a2,s1,344
    80002ed6:	588c                	lw	a1,48(s1)
    80002ed8:	00005517          	auipc	a0,0x5
    80002edc:	55050513          	addi	a0,a0,1360 # 80008428 <states.0+0x150>
    80002ee0:	ffffd097          	auipc	ra,0xffffd
    80002ee4:	6a8080e7          	jalr	1704(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ee8:	6cbc                	ld	a5,88(s1)
    80002eea:	577d                	li	a4,-1
    80002eec:	fbb8                	sd	a4,112(a5)
  }
}
    80002eee:	60e2                	ld	ra,24(sp)
    80002ef0:	6442                	ld	s0,16(sp)
    80002ef2:	64a2                	ld	s1,8(sp)
    80002ef4:	6902                	ld	s2,0(sp)
    80002ef6:	6105                	addi	sp,sp,32
    80002ef8:	8082                	ret

0000000080002efa <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002efa:	1101                	addi	sp,sp,-32
    80002efc:	ec06                	sd	ra,24(sp)
    80002efe:	e822                	sd	s0,16(sp)
    80002f00:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002f02:	fec40593          	addi	a1,s0,-20
    80002f06:	4501                	li	a0,0
    80002f08:	00000097          	auipc	ra,0x0
    80002f0c:	f0e080e7          	jalr	-242(ra) # 80002e16 <argint>
  exit(n);
    80002f10:	fec42503          	lw	a0,-20(s0)
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	3a0080e7          	jalr	928(ra) # 800022b4 <exit>
  return 0; // not reached
}
    80002f1c:	4501                	li	a0,0
    80002f1e:	60e2                	ld	ra,24(sp)
    80002f20:	6442                	ld	s0,16(sp)
    80002f22:	6105                	addi	sp,sp,32
    80002f24:	8082                	ret

0000000080002f26 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f26:	1141                	addi	sp,sp,-16
    80002f28:	e406                	sd	ra,8(sp)
    80002f2a:	e022                	sd	s0,0(sp)
    80002f2c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	a7e080e7          	jalr	-1410(ra) # 800019ac <myproc>
}
    80002f36:	5908                	lw	a0,48(a0)
    80002f38:	60a2                	ld	ra,8(sp)
    80002f3a:	6402                	ld	s0,0(sp)
    80002f3c:	0141                	addi	sp,sp,16
    80002f3e:	8082                	ret

0000000080002f40 <sys_fork>:

uint64
sys_fork(void)
{
    80002f40:	1141                	addi	sp,sp,-16
    80002f42:	e406                	sd	ra,8(sp)
    80002f44:	e022                	sd	s0,0(sp)
    80002f46:	0800                	addi	s0,sp,16
  return fork();
    80002f48:	fffff097          	auipc	ra,0xfffff
    80002f4c:	e4c080e7          	jalr	-436(ra) # 80001d94 <fork>
}
    80002f50:	60a2                	ld	ra,8(sp)
    80002f52:	6402                	ld	s0,0(sp)
    80002f54:	0141                	addi	sp,sp,16
    80002f56:	8082                	ret

0000000080002f58 <sys_wait>:

uint64
sys_wait(void)
{
    80002f58:	1101                	addi	sp,sp,-32
    80002f5a:	ec06                	sd	ra,24(sp)
    80002f5c:	e822                	sd	s0,16(sp)
    80002f5e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002f60:	fe840593          	addi	a1,s0,-24
    80002f64:	4501                	li	a0,0
    80002f66:	00000097          	auipc	ra,0x0
    80002f6a:	ed0080e7          	jalr	-304(ra) # 80002e36 <argaddr>
  return wait(p);
    80002f6e:	fe843503          	ld	a0,-24(s0)
    80002f72:	fffff097          	auipc	ra,0xfffff
    80002f76:	4f4080e7          	jalr	1268(ra) # 80002466 <wait>
}
    80002f7a:	60e2                	ld	ra,24(sp)
    80002f7c:	6442                	ld	s0,16(sp)
    80002f7e:	6105                	addi	sp,sp,32
    80002f80:	8082                	ret

0000000080002f82 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f82:	7179                	addi	sp,sp,-48
    80002f84:	f406                	sd	ra,40(sp)
    80002f86:	f022                	sd	s0,32(sp)
    80002f88:	ec26                	sd	s1,24(sp)
    80002f8a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f8c:	fdc40593          	addi	a1,s0,-36
    80002f90:	4501                	li	a0,0
    80002f92:	00000097          	auipc	ra,0x0
    80002f96:	e84080e7          	jalr	-380(ra) # 80002e16 <argint>
  addr = myproc()->sz;
    80002f9a:	fffff097          	auipc	ra,0xfffff
    80002f9e:	a12080e7          	jalr	-1518(ra) # 800019ac <myproc>
    80002fa2:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002fa4:	fdc42503          	lw	a0,-36(s0)
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	d90080e7          	jalr	-624(ra) # 80001d38 <growproc>
    80002fb0:	00054863          	bltz	a0,80002fc0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002fb4:	8526                	mv	a0,s1
    80002fb6:	70a2                	ld	ra,40(sp)
    80002fb8:	7402                	ld	s0,32(sp)
    80002fba:	64e2                	ld	s1,24(sp)
    80002fbc:	6145                	addi	sp,sp,48
    80002fbe:	8082                	ret
    return -1;
    80002fc0:	54fd                	li	s1,-1
    80002fc2:	bfcd                	j	80002fb4 <sys_sbrk+0x32>

0000000080002fc4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fc4:	7139                	addi	sp,sp,-64
    80002fc6:	fc06                	sd	ra,56(sp)
    80002fc8:	f822                	sd	s0,48(sp)
    80002fca:	f426                	sd	s1,40(sp)
    80002fcc:	f04a                	sd	s2,32(sp)
    80002fce:	ec4e                	sd	s3,24(sp)
    80002fd0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002fd2:	fcc40593          	addi	a1,s0,-52
    80002fd6:	4501                	li	a0,0
    80002fd8:	00000097          	auipc	ra,0x0
    80002fdc:	e3e080e7          	jalr	-450(ra) # 80002e16 <argint>
  acquire(&tickslock);
    80002fe0:	00014517          	auipc	a0,0x14
    80002fe4:	3b050513          	addi	a0,a0,944 # 80017390 <tickslock>
    80002fe8:	ffffe097          	auipc	ra,0xffffe
    80002fec:	bee080e7          	jalr	-1042(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002ff0:	00006917          	auipc	s2,0x6
    80002ff4:	90092903          	lw	s2,-1792(s2) # 800088f0 <ticks>
  while (ticks - ticks0 < n)
    80002ff8:	fcc42783          	lw	a5,-52(s0)
    80002ffc:	cf9d                	beqz	a5,8000303a <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ffe:	00014997          	auipc	s3,0x14
    80003002:	39298993          	addi	s3,s3,914 # 80017390 <tickslock>
    80003006:	00006497          	auipc	s1,0x6
    8000300a:	8ea48493          	addi	s1,s1,-1814 # 800088f0 <ticks>
    if (killed(myproc()))
    8000300e:	fffff097          	auipc	ra,0xfffff
    80003012:	99e080e7          	jalr	-1634(ra) # 800019ac <myproc>
    80003016:	fffff097          	auipc	ra,0xfffff
    8000301a:	41e080e7          	jalr	1054(ra) # 80002434 <killed>
    8000301e:	ed15                	bnez	a0,8000305a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003020:	85ce                	mv	a1,s3
    80003022:	8526                	mv	a0,s1
    80003024:	fffff097          	auipc	ra,0xfffff
    80003028:	15c080e7          	jalr	348(ra) # 80002180 <sleep>
  while (ticks - ticks0 < n)
    8000302c:	409c                	lw	a5,0(s1)
    8000302e:	412787bb          	subw	a5,a5,s2
    80003032:	fcc42703          	lw	a4,-52(s0)
    80003036:	fce7ece3          	bltu	a5,a4,8000300e <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000303a:	00014517          	auipc	a0,0x14
    8000303e:	35650513          	addi	a0,a0,854 # 80017390 <tickslock>
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
  return 0;
    8000304a:	4501                	li	a0,0
}
    8000304c:	70e2                	ld	ra,56(sp)
    8000304e:	7442                	ld	s0,48(sp)
    80003050:	74a2                	ld	s1,40(sp)
    80003052:	7902                	ld	s2,32(sp)
    80003054:	69e2                	ld	s3,24(sp)
    80003056:	6121                	addi	sp,sp,64
    80003058:	8082                	ret
      release(&tickslock);
    8000305a:	00014517          	auipc	a0,0x14
    8000305e:	33650513          	addi	a0,a0,822 # 80017390 <tickslock>
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	c28080e7          	jalr	-984(ra) # 80000c8a <release>
      return -1;
    8000306a:	557d                	li	a0,-1
    8000306c:	b7c5                	j	8000304c <sys_sleep+0x88>

000000008000306e <sys_kill>:

uint64
sys_kill(void)
{
    8000306e:	1101                	addi	sp,sp,-32
    80003070:	ec06                	sd	ra,24(sp)
    80003072:	e822                	sd	s0,16(sp)
    80003074:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003076:	fec40593          	addi	a1,s0,-20
    8000307a:	4501                	li	a0,0
    8000307c:	00000097          	auipc	ra,0x0
    80003080:	d9a080e7          	jalr	-614(ra) # 80002e16 <argint>
  return kill(pid);
    80003084:	fec42503          	lw	a0,-20(s0)
    80003088:	fffff097          	auipc	ra,0xfffff
    8000308c:	30e080e7          	jalr	782(ra) # 80002396 <kill>
}
    80003090:	60e2                	ld	ra,24(sp)
    80003092:	6442                	ld	s0,16(sp)
    80003094:	6105                	addi	sp,sp,32
    80003096:	8082                	ret

0000000080003098 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003098:	1101                	addi	sp,sp,-32
    8000309a:	ec06                	sd	ra,24(sp)
    8000309c:	e822                	sd	s0,16(sp)
    8000309e:	e426                	sd	s1,8(sp)
    800030a0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030a2:	00014517          	auipc	a0,0x14
    800030a6:	2ee50513          	addi	a0,a0,750 # 80017390 <tickslock>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	b2c080e7          	jalr	-1236(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800030b2:	00006497          	auipc	s1,0x6
    800030b6:	83e4a483          	lw	s1,-1986(s1) # 800088f0 <ticks>
  release(&tickslock);
    800030ba:	00014517          	auipc	a0,0x14
    800030be:	2d650513          	addi	a0,a0,726 # 80017390 <tickslock>
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	bc8080e7          	jalr	-1080(ra) # 80000c8a <release>
  return xticks;
}
    800030ca:	02049513          	slli	a0,s1,0x20
    800030ce:	9101                	srli	a0,a0,0x20
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	64a2                	ld	s1,8(sp)
    800030d6:	6105                	addi	sp,sp,32
    800030d8:	8082                	ret

00000000800030da <sys_waitx>:

uint64
sys_waitx(void)
{
    800030da:	7139                	addi	sp,sp,-64
    800030dc:	fc06                	sd	ra,56(sp)
    800030de:	f822                	sd	s0,48(sp)
    800030e0:	f426                	sd	s1,40(sp)
    800030e2:	f04a                	sd	s2,32(sp)
    800030e4:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800030e6:	fd840593          	addi	a1,s0,-40
    800030ea:	4501                	li	a0,0
    800030ec:	00000097          	auipc	ra,0x0
    800030f0:	d4a080e7          	jalr	-694(ra) # 80002e36 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800030f4:	fd040593          	addi	a1,s0,-48
    800030f8:	4505                	li	a0,1
    800030fa:	00000097          	auipc	ra,0x0
    800030fe:	d3c080e7          	jalr	-708(ra) # 80002e36 <argaddr>
  argaddr(2, &addr2);
    80003102:	fc840593          	addi	a1,s0,-56
    80003106:	4509                	li	a0,2
    80003108:	00000097          	auipc	ra,0x0
    8000310c:	d2e080e7          	jalr	-722(ra) # 80002e36 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003110:	fc040613          	addi	a2,s0,-64
    80003114:	fc440593          	addi	a1,s0,-60
    80003118:	fd843503          	ld	a0,-40(s0)
    8000311c:	fffff097          	auipc	ra,0xfffff
    80003120:	5d2080e7          	jalr	1490(ra) # 800026ee <waitx>
    80003124:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003126:	fffff097          	auipc	ra,0xfffff
    8000312a:	886080e7          	jalr	-1914(ra) # 800019ac <myproc>
    8000312e:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003130:	4691                	li	a3,4
    80003132:	fc440613          	addi	a2,s0,-60
    80003136:	fd043583          	ld	a1,-48(s0)
    8000313a:	6928                	ld	a0,80(a0)
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	52c080e7          	jalr	1324(ra) # 80001668 <copyout>
    return -1;
    80003144:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003146:	00054f63          	bltz	a0,80003164 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000314a:	4691                	li	a3,4
    8000314c:	fc040613          	addi	a2,s0,-64
    80003150:	fc843583          	ld	a1,-56(s0)
    80003154:	68a8                	ld	a0,80(s1)
    80003156:	ffffe097          	auipc	ra,0xffffe
    8000315a:	512080e7          	jalr	1298(ra) # 80001668 <copyout>
    8000315e:	00054a63          	bltz	a0,80003172 <sys_waitx+0x98>
    return -1;
  return ret;
    80003162:	87ca                	mv	a5,s2
}
    80003164:	853e                	mv	a0,a5
    80003166:	70e2                	ld	ra,56(sp)
    80003168:	7442                	ld	s0,48(sp)
    8000316a:	74a2                	ld	s1,40(sp)
    8000316c:	7902                	ld	s2,32(sp)
    8000316e:	6121                	addi	sp,sp,64
    80003170:	8082                	ret
    return -1;
    80003172:	57fd                	li	a5,-1
    80003174:	bfc5                	j	80003164 <sys_waitx+0x8a>

0000000080003176 <sys_set_priority>:

int sys_set_priority(void)
{
    80003176:	7179                	addi	sp,sp,-48
    80003178:	f406                	sd	ra,40(sp)
    8000317a:	f022                	sd	s0,32(sp)
    8000317c:	ec26                	sd	s1,24(sp)
    8000317e:	e84a                	sd	s2,16(sp)
    80003180:	1800                	addi	s0,sp,48
  int pid, priority;
  argint(0, &pid);
    80003182:	fdc40593          	addi	a1,s0,-36
    80003186:	4501                	li	a0,0
    80003188:	00000097          	auipc	ra,0x0
    8000318c:	c8e080e7          	jalr	-882(ra) # 80002e16 <argint>
  argint(1, &priority);
    80003190:	fd840593          	addi	a1,s0,-40
    80003194:	4505                	li	a0,1
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	c80080e7          	jalr	-896(ra) # 80002e16 <argint>
  if (priority >= 0 && priority <= 100)
    8000319e:	fd842703          	lw	a4,-40(s0)
    800031a2:	06400793          	li	a5,100
    800031a6:	08e7e563          	bltu	a5,a4,80003230 <sys_set_priority+0xba>
  {
    int previousDP = -1;
    struct proc *myproc;
    for (myproc = proc; myproc < &proc[NPROC]; myproc++)
    800031aa:	0000e497          	auipc	s1,0xe
    800031ae:	de648493          	addi	s1,s1,-538 # 80010f90 <proc>
    800031b2:	00014917          	auipc	s2,0x14
    800031b6:	1de90913          	addi	s2,s2,478 # 80017390 <tickslock>
    {
      acquire(&myproc->lock);
    800031ba:	8526                	mv	a0,s1
    800031bc:	ffffe097          	auipc	ra,0xffffe
    800031c0:	a1a080e7          	jalr	-1510(ra) # 80000bd6 <acquire>
      if (myproc->pid == pid)
    800031c4:	5898                	lw	a4,48(s1)
    800031c6:	fdc42783          	lw	a5,-36(s0)
    800031ca:	00f70d63          	beq	a4,a5,800031e4 <sys_set_priority+0x6e>
          newPriority = 100;
        myproc->DP = newPriority;
        release(&myproc->lock);
        break;
      }
      release(&myproc->lock);
    800031ce:	8526                	mv	a0,s1
    800031d0:	ffffe097          	auipc	ra,0xffffe
    800031d4:	aba080e7          	jalr	-1350(ra) # 80000c8a <release>
    for (myproc = proc; myproc < &proc[NPROC]; myproc++)
    800031d8:	19048493          	addi	s1,s1,400
    800031dc:	fd249fe3          	bne	s1,s2,800031ba <sys_set_priority+0x44>
    int previousDP = -1;
    800031e0:	597d                	li	s2,-1
    800031e2:	a03d                	j	80003210 <sys_set_priority+0x9a>
        previousDP = myproc->DP;
    800031e4:	1884a903          	lw	s2,392(s1)
        myproc->SP = priority;
    800031e8:	fd842783          	lw	a5,-40(s0)
    800031ec:	18f4a223          	sw	a5,388(s1)
        int newPriority = RBI + priority;
    800031f0:	27e5                	addiw	a5,a5,25
        myproc->DP = newPriority;
    800031f2:	873e                	mv	a4,a5
    800031f4:	2781                	sext.w	a5,a5
    800031f6:	06400693          	li	a3,100
    800031fa:	00f6d463          	bge	a3,a5,80003202 <sys_set_priority+0x8c>
    800031fe:	06400713          	li	a4,100
    80003202:	18e4a423          	sw	a4,392(s1)
        release(&myproc->lock);
    80003206:	8526                	mv	a0,s1
    80003208:	ffffe097          	auipc	ra,0xffffe
    8000320c:	a82080e7          	jalr	-1406(ra) # 80000c8a <release>
    }
    if (previousDP > priority)
    80003210:	fd842783          	lw	a5,-40(s0)
    80003214:	0127c963          	blt	a5,s2,80003226 <sys_set_priority+0xb0>
  }
  else
  {
    return -1;
  }
    80003218:	854a                	mv	a0,s2
    8000321a:	70a2                	ld	ra,40(sp)
    8000321c:	7402                	ld	s0,32(sp)
    8000321e:	64e2                	ld	s1,24(sp)
    80003220:	6942                	ld	s2,16(sp)
    80003222:	6145                	addi	sp,sp,48
    80003224:	8082                	ret
      yield();
    80003226:	fffff097          	auipc	ra,0xfffff
    8000322a:	f1e080e7          	jalr	-226(ra) # 80002144 <yield>
    8000322e:	b7ed                	j	80003218 <sys_set_priority+0xa2>
    return -1;
    80003230:	597d                	li	s2,-1
    80003232:	b7dd                	j	80003218 <sys_set_priority+0xa2>

0000000080003234 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003234:	7179                	addi	sp,sp,-48
    80003236:	f406                	sd	ra,40(sp)
    80003238:	f022                	sd	s0,32(sp)
    8000323a:	ec26                	sd	s1,24(sp)
    8000323c:	e84a                	sd	s2,16(sp)
    8000323e:	e44e                	sd	s3,8(sp)
    80003240:	e052                	sd	s4,0(sp)
    80003242:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003244:	00005597          	auipc	a1,0x5
    80003248:	2e458593          	addi	a1,a1,740 # 80008528 <syscalls+0xc8>
    8000324c:	00014517          	auipc	a0,0x14
    80003250:	15c50513          	addi	a0,a0,348 # 800173a8 <bcache>
    80003254:	ffffe097          	auipc	ra,0xffffe
    80003258:	8f2080e7          	jalr	-1806(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000325c:	0001c797          	auipc	a5,0x1c
    80003260:	14c78793          	addi	a5,a5,332 # 8001f3a8 <bcache+0x8000>
    80003264:	0001c717          	auipc	a4,0x1c
    80003268:	3ac70713          	addi	a4,a4,940 # 8001f610 <bcache+0x8268>
    8000326c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003270:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003274:	00014497          	auipc	s1,0x14
    80003278:	14c48493          	addi	s1,s1,332 # 800173c0 <bcache+0x18>
    b->next = bcache.head.next;
    8000327c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000327e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003280:	00005a17          	auipc	s4,0x5
    80003284:	2b0a0a13          	addi	s4,s4,688 # 80008530 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003288:	2b893783          	ld	a5,696(s2)
    8000328c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000328e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003292:	85d2                	mv	a1,s4
    80003294:	01048513          	addi	a0,s1,16
    80003298:	00001097          	auipc	ra,0x1
    8000329c:	4c4080e7          	jalr	1220(ra) # 8000475c <initsleeplock>
    bcache.head.next->prev = b;
    800032a0:	2b893783          	ld	a5,696(s2)
    800032a4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032a6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032aa:	45848493          	addi	s1,s1,1112
    800032ae:	fd349de3          	bne	s1,s3,80003288 <binit+0x54>
  }
}
    800032b2:	70a2                	ld	ra,40(sp)
    800032b4:	7402                	ld	s0,32(sp)
    800032b6:	64e2                	ld	s1,24(sp)
    800032b8:	6942                	ld	s2,16(sp)
    800032ba:	69a2                	ld	s3,8(sp)
    800032bc:	6a02                	ld	s4,0(sp)
    800032be:	6145                	addi	sp,sp,48
    800032c0:	8082                	ret

00000000800032c2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032c2:	7179                	addi	sp,sp,-48
    800032c4:	f406                	sd	ra,40(sp)
    800032c6:	f022                	sd	s0,32(sp)
    800032c8:	ec26                	sd	s1,24(sp)
    800032ca:	e84a                	sd	s2,16(sp)
    800032cc:	e44e                	sd	s3,8(sp)
    800032ce:	1800                	addi	s0,sp,48
    800032d0:	892a                	mv	s2,a0
    800032d2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800032d4:	00014517          	auipc	a0,0x14
    800032d8:	0d450513          	addi	a0,a0,212 # 800173a8 <bcache>
    800032dc:	ffffe097          	auipc	ra,0xffffe
    800032e0:	8fa080e7          	jalr	-1798(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800032e4:	0001c497          	auipc	s1,0x1c
    800032e8:	37c4b483          	ld	s1,892(s1) # 8001f660 <bcache+0x82b8>
    800032ec:	0001c797          	auipc	a5,0x1c
    800032f0:	32478793          	addi	a5,a5,804 # 8001f610 <bcache+0x8268>
    800032f4:	02f48f63          	beq	s1,a5,80003332 <bread+0x70>
    800032f8:	873e                	mv	a4,a5
    800032fa:	a021                	j	80003302 <bread+0x40>
    800032fc:	68a4                	ld	s1,80(s1)
    800032fe:	02e48a63          	beq	s1,a4,80003332 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003302:	449c                	lw	a5,8(s1)
    80003304:	ff279ce3          	bne	a5,s2,800032fc <bread+0x3a>
    80003308:	44dc                	lw	a5,12(s1)
    8000330a:	ff3799e3          	bne	a5,s3,800032fc <bread+0x3a>
      b->refcnt++;
    8000330e:	40bc                	lw	a5,64(s1)
    80003310:	2785                	addiw	a5,a5,1
    80003312:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003314:	00014517          	auipc	a0,0x14
    80003318:	09450513          	addi	a0,a0,148 # 800173a8 <bcache>
    8000331c:	ffffe097          	auipc	ra,0xffffe
    80003320:	96e080e7          	jalr	-1682(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003324:	01048513          	addi	a0,s1,16
    80003328:	00001097          	auipc	ra,0x1
    8000332c:	46e080e7          	jalr	1134(ra) # 80004796 <acquiresleep>
      return b;
    80003330:	a8b9                	j	8000338e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003332:	0001c497          	auipc	s1,0x1c
    80003336:	3264b483          	ld	s1,806(s1) # 8001f658 <bcache+0x82b0>
    8000333a:	0001c797          	auipc	a5,0x1c
    8000333e:	2d678793          	addi	a5,a5,726 # 8001f610 <bcache+0x8268>
    80003342:	00f48863          	beq	s1,a5,80003352 <bread+0x90>
    80003346:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003348:	40bc                	lw	a5,64(s1)
    8000334a:	cf81                	beqz	a5,80003362 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000334c:	64a4                	ld	s1,72(s1)
    8000334e:	fee49de3          	bne	s1,a4,80003348 <bread+0x86>
  panic("bget: no buffers");
    80003352:	00005517          	auipc	a0,0x5
    80003356:	1e650513          	addi	a0,a0,486 # 80008538 <syscalls+0xd8>
    8000335a:	ffffd097          	auipc	ra,0xffffd
    8000335e:	1e4080e7          	jalr	484(ra) # 8000053e <panic>
      b->dev = dev;
    80003362:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003366:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000336a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000336e:	4785                	li	a5,1
    80003370:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003372:	00014517          	auipc	a0,0x14
    80003376:	03650513          	addi	a0,a0,54 # 800173a8 <bcache>
    8000337a:	ffffe097          	auipc	ra,0xffffe
    8000337e:	910080e7          	jalr	-1776(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003382:	01048513          	addi	a0,s1,16
    80003386:	00001097          	auipc	ra,0x1
    8000338a:	410080e7          	jalr	1040(ra) # 80004796 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000338e:	409c                	lw	a5,0(s1)
    80003390:	cb89                	beqz	a5,800033a2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003392:	8526                	mv	a0,s1
    80003394:	70a2                	ld	ra,40(sp)
    80003396:	7402                	ld	s0,32(sp)
    80003398:	64e2                	ld	s1,24(sp)
    8000339a:	6942                	ld	s2,16(sp)
    8000339c:	69a2                	ld	s3,8(sp)
    8000339e:	6145                	addi	sp,sp,48
    800033a0:	8082                	ret
    virtio_disk_rw(b, 0);
    800033a2:	4581                	li	a1,0
    800033a4:	8526                	mv	a0,s1
    800033a6:	00003097          	auipc	ra,0x3
    800033aa:	ffe080e7          	jalr	-2(ra) # 800063a4 <virtio_disk_rw>
    b->valid = 1;
    800033ae:	4785                	li	a5,1
    800033b0:	c09c                	sw	a5,0(s1)
  return b;
    800033b2:	b7c5                	j	80003392 <bread+0xd0>

00000000800033b4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033b4:	1101                	addi	sp,sp,-32
    800033b6:	ec06                	sd	ra,24(sp)
    800033b8:	e822                	sd	s0,16(sp)
    800033ba:	e426                	sd	s1,8(sp)
    800033bc:	1000                	addi	s0,sp,32
    800033be:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033c0:	0541                	addi	a0,a0,16
    800033c2:	00001097          	auipc	ra,0x1
    800033c6:	46e080e7          	jalr	1134(ra) # 80004830 <holdingsleep>
    800033ca:	cd01                	beqz	a0,800033e2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033cc:	4585                	li	a1,1
    800033ce:	8526                	mv	a0,s1
    800033d0:	00003097          	auipc	ra,0x3
    800033d4:	fd4080e7          	jalr	-44(ra) # 800063a4 <virtio_disk_rw>
}
    800033d8:	60e2                	ld	ra,24(sp)
    800033da:	6442                	ld	s0,16(sp)
    800033dc:	64a2                	ld	s1,8(sp)
    800033de:	6105                	addi	sp,sp,32
    800033e0:	8082                	ret
    panic("bwrite");
    800033e2:	00005517          	auipc	a0,0x5
    800033e6:	16e50513          	addi	a0,a0,366 # 80008550 <syscalls+0xf0>
    800033ea:	ffffd097          	auipc	ra,0xffffd
    800033ee:	154080e7          	jalr	340(ra) # 8000053e <panic>

00000000800033f2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800033f2:	1101                	addi	sp,sp,-32
    800033f4:	ec06                	sd	ra,24(sp)
    800033f6:	e822                	sd	s0,16(sp)
    800033f8:	e426                	sd	s1,8(sp)
    800033fa:	e04a                	sd	s2,0(sp)
    800033fc:	1000                	addi	s0,sp,32
    800033fe:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003400:	01050913          	addi	s2,a0,16
    80003404:	854a                	mv	a0,s2
    80003406:	00001097          	auipc	ra,0x1
    8000340a:	42a080e7          	jalr	1066(ra) # 80004830 <holdingsleep>
    8000340e:	c92d                	beqz	a0,80003480 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003410:	854a                	mv	a0,s2
    80003412:	00001097          	auipc	ra,0x1
    80003416:	3da080e7          	jalr	986(ra) # 800047ec <releasesleep>

  acquire(&bcache.lock);
    8000341a:	00014517          	auipc	a0,0x14
    8000341e:	f8e50513          	addi	a0,a0,-114 # 800173a8 <bcache>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	7b4080e7          	jalr	1972(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000342a:	40bc                	lw	a5,64(s1)
    8000342c:	37fd                	addiw	a5,a5,-1
    8000342e:	0007871b          	sext.w	a4,a5
    80003432:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003434:	eb05                	bnez	a4,80003464 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003436:	68bc                	ld	a5,80(s1)
    80003438:	64b8                	ld	a4,72(s1)
    8000343a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000343c:	64bc                	ld	a5,72(s1)
    8000343e:	68b8                	ld	a4,80(s1)
    80003440:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003442:	0001c797          	auipc	a5,0x1c
    80003446:	f6678793          	addi	a5,a5,-154 # 8001f3a8 <bcache+0x8000>
    8000344a:	2b87b703          	ld	a4,696(a5)
    8000344e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003450:	0001c717          	auipc	a4,0x1c
    80003454:	1c070713          	addi	a4,a4,448 # 8001f610 <bcache+0x8268>
    80003458:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000345a:	2b87b703          	ld	a4,696(a5)
    8000345e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003460:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003464:	00014517          	auipc	a0,0x14
    80003468:	f4450513          	addi	a0,a0,-188 # 800173a8 <bcache>
    8000346c:	ffffe097          	auipc	ra,0xffffe
    80003470:	81e080e7          	jalr	-2018(ra) # 80000c8a <release>
}
    80003474:	60e2                	ld	ra,24(sp)
    80003476:	6442                	ld	s0,16(sp)
    80003478:	64a2                	ld	s1,8(sp)
    8000347a:	6902                	ld	s2,0(sp)
    8000347c:	6105                	addi	sp,sp,32
    8000347e:	8082                	ret
    panic("brelse");
    80003480:	00005517          	auipc	a0,0x5
    80003484:	0d850513          	addi	a0,a0,216 # 80008558 <syscalls+0xf8>
    80003488:	ffffd097          	auipc	ra,0xffffd
    8000348c:	0b6080e7          	jalr	182(ra) # 8000053e <panic>

0000000080003490 <bpin>:

void
bpin(struct buf *b) {
    80003490:	1101                	addi	sp,sp,-32
    80003492:	ec06                	sd	ra,24(sp)
    80003494:	e822                	sd	s0,16(sp)
    80003496:	e426                	sd	s1,8(sp)
    80003498:	1000                	addi	s0,sp,32
    8000349a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000349c:	00014517          	auipc	a0,0x14
    800034a0:	f0c50513          	addi	a0,a0,-244 # 800173a8 <bcache>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	732080e7          	jalr	1842(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800034ac:	40bc                	lw	a5,64(s1)
    800034ae:	2785                	addiw	a5,a5,1
    800034b0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034b2:	00014517          	auipc	a0,0x14
    800034b6:	ef650513          	addi	a0,a0,-266 # 800173a8 <bcache>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	7d0080e7          	jalr	2000(ra) # 80000c8a <release>
}
    800034c2:	60e2                	ld	ra,24(sp)
    800034c4:	6442                	ld	s0,16(sp)
    800034c6:	64a2                	ld	s1,8(sp)
    800034c8:	6105                	addi	sp,sp,32
    800034ca:	8082                	ret

00000000800034cc <bunpin>:

void
bunpin(struct buf *b) {
    800034cc:	1101                	addi	sp,sp,-32
    800034ce:	ec06                	sd	ra,24(sp)
    800034d0:	e822                	sd	s0,16(sp)
    800034d2:	e426                	sd	s1,8(sp)
    800034d4:	1000                	addi	s0,sp,32
    800034d6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034d8:	00014517          	auipc	a0,0x14
    800034dc:	ed050513          	addi	a0,a0,-304 # 800173a8 <bcache>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	6f6080e7          	jalr	1782(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800034e8:	40bc                	lw	a5,64(s1)
    800034ea:	37fd                	addiw	a5,a5,-1
    800034ec:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034ee:	00014517          	auipc	a0,0x14
    800034f2:	eba50513          	addi	a0,a0,-326 # 800173a8 <bcache>
    800034f6:	ffffd097          	auipc	ra,0xffffd
    800034fa:	794080e7          	jalr	1940(ra) # 80000c8a <release>
}
    800034fe:	60e2                	ld	ra,24(sp)
    80003500:	6442                	ld	s0,16(sp)
    80003502:	64a2                	ld	s1,8(sp)
    80003504:	6105                	addi	sp,sp,32
    80003506:	8082                	ret

0000000080003508 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003508:	1101                	addi	sp,sp,-32
    8000350a:	ec06                	sd	ra,24(sp)
    8000350c:	e822                	sd	s0,16(sp)
    8000350e:	e426                	sd	s1,8(sp)
    80003510:	e04a                	sd	s2,0(sp)
    80003512:	1000                	addi	s0,sp,32
    80003514:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003516:	00d5d59b          	srliw	a1,a1,0xd
    8000351a:	0001c797          	auipc	a5,0x1c
    8000351e:	56a7a783          	lw	a5,1386(a5) # 8001fa84 <sb+0x1c>
    80003522:	9dbd                	addw	a1,a1,a5
    80003524:	00000097          	auipc	ra,0x0
    80003528:	d9e080e7          	jalr	-610(ra) # 800032c2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000352c:	0074f713          	andi	a4,s1,7
    80003530:	4785                	li	a5,1
    80003532:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003536:	14ce                	slli	s1,s1,0x33
    80003538:	90d9                	srli	s1,s1,0x36
    8000353a:	00950733          	add	a4,a0,s1
    8000353e:	05874703          	lbu	a4,88(a4)
    80003542:	00e7f6b3          	and	a3,a5,a4
    80003546:	c69d                	beqz	a3,80003574 <bfree+0x6c>
    80003548:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000354a:	94aa                	add	s1,s1,a0
    8000354c:	fff7c793          	not	a5,a5
    80003550:	8ff9                	and	a5,a5,a4
    80003552:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003556:	00001097          	auipc	ra,0x1
    8000355a:	120080e7          	jalr	288(ra) # 80004676 <log_write>
  brelse(bp);
    8000355e:	854a                	mv	a0,s2
    80003560:	00000097          	auipc	ra,0x0
    80003564:	e92080e7          	jalr	-366(ra) # 800033f2 <brelse>
}
    80003568:	60e2                	ld	ra,24(sp)
    8000356a:	6442                	ld	s0,16(sp)
    8000356c:	64a2                	ld	s1,8(sp)
    8000356e:	6902                	ld	s2,0(sp)
    80003570:	6105                	addi	sp,sp,32
    80003572:	8082                	ret
    panic("freeing free block");
    80003574:	00005517          	auipc	a0,0x5
    80003578:	fec50513          	addi	a0,a0,-20 # 80008560 <syscalls+0x100>
    8000357c:	ffffd097          	auipc	ra,0xffffd
    80003580:	fc2080e7          	jalr	-62(ra) # 8000053e <panic>

0000000080003584 <balloc>:
{
    80003584:	711d                	addi	sp,sp,-96
    80003586:	ec86                	sd	ra,88(sp)
    80003588:	e8a2                	sd	s0,80(sp)
    8000358a:	e4a6                	sd	s1,72(sp)
    8000358c:	e0ca                	sd	s2,64(sp)
    8000358e:	fc4e                	sd	s3,56(sp)
    80003590:	f852                	sd	s4,48(sp)
    80003592:	f456                	sd	s5,40(sp)
    80003594:	f05a                	sd	s6,32(sp)
    80003596:	ec5e                	sd	s7,24(sp)
    80003598:	e862                	sd	s8,16(sp)
    8000359a:	e466                	sd	s9,8(sp)
    8000359c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000359e:	0001c797          	auipc	a5,0x1c
    800035a2:	4ce7a783          	lw	a5,1230(a5) # 8001fa6c <sb+0x4>
    800035a6:	10078163          	beqz	a5,800036a8 <balloc+0x124>
    800035aa:	8baa                	mv	s7,a0
    800035ac:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035ae:	0001cb17          	auipc	s6,0x1c
    800035b2:	4bab0b13          	addi	s6,s6,1210 # 8001fa68 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035b6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035b8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035ba:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035bc:	6c89                	lui	s9,0x2
    800035be:	a061                	j	80003646 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035c0:	974a                	add	a4,a4,s2
    800035c2:	8fd5                	or	a5,a5,a3
    800035c4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800035c8:	854a                	mv	a0,s2
    800035ca:	00001097          	auipc	ra,0x1
    800035ce:	0ac080e7          	jalr	172(ra) # 80004676 <log_write>
        brelse(bp);
    800035d2:	854a                	mv	a0,s2
    800035d4:	00000097          	auipc	ra,0x0
    800035d8:	e1e080e7          	jalr	-482(ra) # 800033f2 <brelse>
  bp = bread(dev, bno);
    800035dc:	85a6                	mv	a1,s1
    800035de:	855e                	mv	a0,s7
    800035e0:	00000097          	auipc	ra,0x0
    800035e4:	ce2080e7          	jalr	-798(ra) # 800032c2 <bread>
    800035e8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800035ea:	40000613          	li	a2,1024
    800035ee:	4581                	li	a1,0
    800035f0:	05850513          	addi	a0,a0,88
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	6de080e7          	jalr	1758(ra) # 80000cd2 <memset>
  log_write(bp);
    800035fc:	854a                	mv	a0,s2
    800035fe:	00001097          	auipc	ra,0x1
    80003602:	078080e7          	jalr	120(ra) # 80004676 <log_write>
  brelse(bp);
    80003606:	854a                	mv	a0,s2
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	dea080e7          	jalr	-534(ra) # 800033f2 <brelse>
}
    80003610:	8526                	mv	a0,s1
    80003612:	60e6                	ld	ra,88(sp)
    80003614:	6446                	ld	s0,80(sp)
    80003616:	64a6                	ld	s1,72(sp)
    80003618:	6906                	ld	s2,64(sp)
    8000361a:	79e2                	ld	s3,56(sp)
    8000361c:	7a42                	ld	s4,48(sp)
    8000361e:	7aa2                	ld	s5,40(sp)
    80003620:	7b02                	ld	s6,32(sp)
    80003622:	6be2                	ld	s7,24(sp)
    80003624:	6c42                	ld	s8,16(sp)
    80003626:	6ca2                	ld	s9,8(sp)
    80003628:	6125                	addi	sp,sp,96
    8000362a:	8082                	ret
    brelse(bp);
    8000362c:	854a                	mv	a0,s2
    8000362e:	00000097          	auipc	ra,0x0
    80003632:	dc4080e7          	jalr	-572(ra) # 800033f2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003636:	015c87bb          	addw	a5,s9,s5
    8000363a:	00078a9b          	sext.w	s5,a5
    8000363e:	004b2703          	lw	a4,4(s6)
    80003642:	06eaf363          	bgeu	s5,a4,800036a8 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003646:	41fad79b          	sraiw	a5,s5,0x1f
    8000364a:	0137d79b          	srliw	a5,a5,0x13
    8000364e:	015787bb          	addw	a5,a5,s5
    80003652:	40d7d79b          	sraiw	a5,a5,0xd
    80003656:	01cb2583          	lw	a1,28(s6)
    8000365a:	9dbd                	addw	a1,a1,a5
    8000365c:	855e                	mv	a0,s7
    8000365e:	00000097          	auipc	ra,0x0
    80003662:	c64080e7          	jalr	-924(ra) # 800032c2 <bread>
    80003666:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003668:	004b2503          	lw	a0,4(s6)
    8000366c:	000a849b          	sext.w	s1,s5
    80003670:	8662                	mv	a2,s8
    80003672:	faa4fde3          	bgeu	s1,a0,8000362c <balloc+0xa8>
      m = 1 << (bi % 8);
    80003676:	41f6579b          	sraiw	a5,a2,0x1f
    8000367a:	01d7d69b          	srliw	a3,a5,0x1d
    8000367e:	00c6873b          	addw	a4,a3,a2
    80003682:	00777793          	andi	a5,a4,7
    80003686:	9f95                	subw	a5,a5,a3
    80003688:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000368c:	4037571b          	sraiw	a4,a4,0x3
    80003690:	00e906b3          	add	a3,s2,a4
    80003694:	0586c683          	lbu	a3,88(a3)
    80003698:	00d7f5b3          	and	a1,a5,a3
    8000369c:	d195                	beqz	a1,800035c0 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000369e:	2605                	addiw	a2,a2,1
    800036a0:	2485                	addiw	s1,s1,1
    800036a2:	fd4618e3          	bne	a2,s4,80003672 <balloc+0xee>
    800036a6:	b759                	j	8000362c <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800036a8:	00005517          	auipc	a0,0x5
    800036ac:	ed050513          	addi	a0,a0,-304 # 80008578 <syscalls+0x118>
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	ed8080e7          	jalr	-296(ra) # 80000588 <printf>
  return 0;
    800036b8:	4481                	li	s1,0
    800036ba:	bf99                	j	80003610 <balloc+0x8c>

00000000800036bc <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800036bc:	7179                	addi	sp,sp,-48
    800036be:	f406                	sd	ra,40(sp)
    800036c0:	f022                	sd	s0,32(sp)
    800036c2:	ec26                	sd	s1,24(sp)
    800036c4:	e84a                	sd	s2,16(sp)
    800036c6:	e44e                	sd	s3,8(sp)
    800036c8:	e052                	sd	s4,0(sp)
    800036ca:	1800                	addi	s0,sp,48
    800036cc:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036ce:	47ad                	li	a5,11
    800036d0:	02b7e763          	bltu	a5,a1,800036fe <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800036d4:	02059493          	slli	s1,a1,0x20
    800036d8:	9081                	srli	s1,s1,0x20
    800036da:	048a                	slli	s1,s1,0x2
    800036dc:	94aa                	add	s1,s1,a0
    800036de:	0504a903          	lw	s2,80(s1)
    800036e2:	06091e63          	bnez	s2,8000375e <bmap+0xa2>
      addr = balloc(ip->dev);
    800036e6:	4108                	lw	a0,0(a0)
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	e9c080e7          	jalr	-356(ra) # 80003584 <balloc>
    800036f0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800036f4:	06090563          	beqz	s2,8000375e <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800036f8:	0524a823          	sw	s2,80(s1)
    800036fc:	a08d                	j	8000375e <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800036fe:	ff45849b          	addiw	s1,a1,-12
    80003702:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003706:	0ff00793          	li	a5,255
    8000370a:	08e7e563          	bltu	a5,a4,80003794 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000370e:	08052903          	lw	s2,128(a0)
    80003712:	00091d63          	bnez	s2,8000372c <bmap+0x70>
      addr = balloc(ip->dev);
    80003716:	4108                	lw	a0,0(a0)
    80003718:	00000097          	auipc	ra,0x0
    8000371c:	e6c080e7          	jalr	-404(ra) # 80003584 <balloc>
    80003720:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003724:	02090d63          	beqz	s2,8000375e <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003728:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000372c:	85ca                	mv	a1,s2
    8000372e:	0009a503          	lw	a0,0(s3)
    80003732:	00000097          	auipc	ra,0x0
    80003736:	b90080e7          	jalr	-1136(ra) # 800032c2 <bread>
    8000373a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000373c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003740:	02049593          	slli	a1,s1,0x20
    80003744:	9181                	srli	a1,a1,0x20
    80003746:	058a                	slli	a1,a1,0x2
    80003748:	00b784b3          	add	s1,a5,a1
    8000374c:	0004a903          	lw	s2,0(s1)
    80003750:	02090063          	beqz	s2,80003770 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003754:	8552                	mv	a0,s4
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	c9c080e7          	jalr	-868(ra) # 800033f2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000375e:	854a                	mv	a0,s2
    80003760:	70a2                	ld	ra,40(sp)
    80003762:	7402                	ld	s0,32(sp)
    80003764:	64e2                	ld	s1,24(sp)
    80003766:	6942                	ld	s2,16(sp)
    80003768:	69a2                	ld	s3,8(sp)
    8000376a:	6a02                	ld	s4,0(sp)
    8000376c:	6145                	addi	sp,sp,48
    8000376e:	8082                	ret
      addr = balloc(ip->dev);
    80003770:	0009a503          	lw	a0,0(s3)
    80003774:	00000097          	auipc	ra,0x0
    80003778:	e10080e7          	jalr	-496(ra) # 80003584 <balloc>
    8000377c:	0005091b          	sext.w	s2,a0
      if(addr){
    80003780:	fc090ae3          	beqz	s2,80003754 <bmap+0x98>
        a[bn] = addr;
    80003784:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003788:	8552                	mv	a0,s4
    8000378a:	00001097          	auipc	ra,0x1
    8000378e:	eec080e7          	jalr	-276(ra) # 80004676 <log_write>
    80003792:	b7c9                	j	80003754 <bmap+0x98>
  panic("bmap: out of range");
    80003794:	00005517          	auipc	a0,0x5
    80003798:	dfc50513          	addi	a0,a0,-516 # 80008590 <syscalls+0x130>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	da2080e7          	jalr	-606(ra) # 8000053e <panic>

00000000800037a4 <iget>:
{
    800037a4:	7179                	addi	sp,sp,-48
    800037a6:	f406                	sd	ra,40(sp)
    800037a8:	f022                	sd	s0,32(sp)
    800037aa:	ec26                	sd	s1,24(sp)
    800037ac:	e84a                	sd	s2,16(sp)
    800037ae:	e44e                	sd	s3,8(sp)
    800037b0:	e052                	sd	s4,0(sp)
    800037b2:	1800                	addi	s0,sp,48
    800037b4:	89aa                	mv	s3,a0
    800037b6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037b8:	0001c517          	auipc	a0,0x1c
    800037bc:	2d050513          	addi	a0,a0,720 # 8001fa88 <itable>
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	416080e7          	jalr	1046(ra) # 80000bd6 <acquire>
  empty = 0;
    800037c8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037ca:	0001c497          	auipc	s1,0x1c
    800037ce:	2d648493          	addi	s1,s1,726 # 8001faa0 <itable+0x18>
    800037d2:	0001e697          	auipc	a3,0x1e
    800037d6:	d5e68693          	addi	a3,a3,-674 # 80021530 <log>
    800037da:	a039                	j	800037e8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037dc:	02090b63          	beqz	s2,80003812 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037e0:	08848493          	addi	s1,s1,136
    800037e4:	02d48a63          	beq	s1,a3,80003818 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037e8:	449c                	lw	a5,8(s1)
    800037ea:	fef059e3          	blez	a5,800037dc <iget+0x38>
    800037ee:	4098                	lw	a4,0(s1)
    800037f0:	ff3716e3          	bne	a4,s3,800037dc <iget+0x38>
    800037f4:	40d8                	lw	a4,4(s1)
    800037f6:	ff4713e3          	bne	a4,s4,800037dc <iget+0x38>
      ip->ref++;
    800037fa:	2785                	addiw	a5,a5,1
    800037fc:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800037fe:	0001c517          	auipc	a0,0x1c
    80003802:	28a50513          	addi	a0,a0,650 # 8001fa88 <itable>
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	484080e7          	jalr	1156(ra) # 80000c8a <release>
      return ip;
    8000380e:	8926                	mv	s2,s1
    80003810:	a03d                	j	8000383e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003812:	f7f9                	bnez	a5,800037e0 <iget+0x3c>
    80003814:	8926                	mv	s2,s1
    80003816:	b7e9                	j	800037e0 <iget+0x3c>
  if(empty == 0)
    80003818:	02090c63          	beqz	s2,80003850 <iget+0xac>
  ip->dev = dev;
    8000381c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003820:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003824:	4785                	li	a5,1
    80003826:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000382a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000382e:	0001c517          	auipc	a0,0x1c
    80003832:	25a50513          	addi	a0,a0,602 # 8001fa88 <itable>
    80003836:	ffffd097          	auipc	ra,0xffffd
    8000383a:	454080e7          	jalr	1108(ra) # 80000c8a <release>
}
    8000383e:	854a                	mv	a0,s2
    80003840:	70a2                	ld	ra,40(sp)
    80003842:	7402                	ld	s0,32(sp)
    80003844:	64e2                	ld	s1,24(sp)
    80003846:	6942                	ld	s2,16(sp)
    80003848:	69a2                	ld	s3,8(sp)
    8000384a:	6a02                	ld	s4,0(sp)
    8000384c:	6145                	addi	sp,sp,48
    8000384e:	8082                	ret
    panic("iget: no inodes");
    80003850:	00005517          	auipc	a0,0x5
    80003854:	d5850513          	addi	a0,a0,-680 # 800085a8 <syscalls+0x148>
    80003858:	ffffd097          	auipc	ra,0xffffd
    8000385c:	ce6080e7          	jalr	-794(ra) # 8000053e <panic>

0000000080003860 <fsinit>:
fsinit(int dev) {
    80003860:	7179                	addi	sp,sp,-48
    80003862:	f406                	sd	ra,40(sp)
    80003864:	f022                	sd	s0,32(sp)
    80003866:	ec26                	sd	s1,24(sp)
    80003868:	e84a                	sd	s2,16(sp)
    8000386a:	e44e                	sd	s3,8(sp)
    8000386c:	1800                	addi	s0,sp,48
    8000386e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003870:	4585                	li	a1,1
    80003872:	00000097          	auipc	ra,0x0
    80003876:	a50080e7          	jalr	-1456(ra) # 800032c2 <bread>
    8000387a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000387c:	0001c997          	auipc	s3,0x1c
    80003880:	1ec98993          	addi	s3,s3,492 # 8001fa68 <sb>
    80003884:	02000613          	li	a2,32
    80003888:	05850593          	addi	a1,a0,88
    8000388c:	854e                	mv	a0,s3
    8000388e:	ffffd097          	auipc	ra,0xffffd
    80003892:	4a0080e7          	jalr	1184(ra) # 80000d2e <memmove>
  brelse(bp);
    80003896:	8526                	mv	a0,s1
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	b5a080e7          	jalr	-1190(ra) # 800033f2 <brelse>
  if(sb.magic != FSMAGIC)
    800038a0:	0009a703          	lw	a4,0(s3)
    800038a4:	102037b7          	lui	a5,0x10203
    800038a8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038ac:	02f71263          	bne	a4,a5,800038d0 <fsinit+0x70>
  initlog(dev, &sb);
    800038b0:	0001c597          	auipc	a1,0x1c
    800038b4:	1b858593          	addi	a1,a1,440 # 8001fa68 <sb>
    800038b8:	854a                	mv	a0,s2
    800038ba:	00001097          	auipc	ra,0x1
    800038be:	b40080e7          	jalr	-1216(ra) # 800043fa <initlog>
}
    800038c2:	70a2                	ld	ra,40(sp)
    800038c4:	7402                	ld	s0,32(sp)
    800038c6:	64e2                	ld	s1,24(sp)
    800038c8:	6942                	ld	s2,16(sp)
    800038ca:	69a2                	ld	s3,8(sp)
    800038cc:	6145                	addi	sp,sp,48
    800038ce:	8082                	ret
    panic("invalid file system");
    800038d0:	00005517          	auipc	a0,0x5
    800038d4:	ce850513          	addi	a0,a0,-792 # 800085b8 <syscalls+0x158>
    800038d8:	ffffd097          	auipc	ra,0xffffd
    800038dc:	c66080e7          	jalr	-922(ra) # 8000053e <panic>

00000000800038e0 <iinit>:
{
    800038e0:	7179                	addi	sp,sp,-48
    800038e2:	f406                	sd	ra,40(sp)
    800038e4:	f022                	sd	s0,32(sp)
    800038e6:	ec26                	sd	s1,24(sp)
    800038e8:	e84a                	sd	s2,16(sp)
    800038ea:	e44e                	sd	s3,8(sp)
    800038ec:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800038ee:	00005597          	auipc	a1,0x5
    800038f2:	ce258593          	addi	a1,a1,-798 # 800085d0 <syscalls+0x170>
    800038f6:	0001c517          	auipc	a0,0x1c
    800038fa:	19250513          	addi	a0,a0,402 # 8001fa88 <itable>
    800038fe:	ffffd097          	auipc	ra,0xffffd
    80003902:	248080e7          	jalr	584(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003906:	0001c497          	auipc	s1,0x1c
    8000390a:	1aa48493          	addi	s1,s1,426 # 8001fab0 <itable+0x28>
    8000390e:	0001e997          	auipc	s3,0x1e
    80003912:	c3298993          	addi	s3,s3,-974 # 80021540 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003916:	00005917          	auipc	s2,0x5
    8000391a:	cc290913          	addi	s2,s2,-830 # 800085d8 <syscalls+0x178>
    8000391e:	85ca                	mv	a1,s2
    80003920:	8526                	mv	a0,s1
    80003922:	00001097          	auipc	ra,0x1
    80003926:	e3a080e7          	jalr	-454(ra) # 8000475c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000392a:	08848493          	addi	s1,s1,136
    8000392e:	ff3498e3          	bne	s1,s3,8000391e <iinit+0x3e>
}
    80003932:	70a2                	ld	ra,40(sp)
    80003934:	7402                	ld	s0,32(sp)
    80003936:	64e2                	ld	s1,24(sp)
    80003938:	6942                	ld	s2,16(sp)
    8000393a:	69a2                	ld	s3,8(sp)
    8000393c:	6145                	addi	sp,sp,48
    8000393e:	8082                	ret

0000000080003940 <ialloc>:
{
    80003940:	715d                	addi	sp,sp,-80
    80003942:	e486                	sd	ra,72(sp)
    80003944:	e0a2                	sd	s0,64(sp)
    80003946:	fc26                	sd	s1,56(sp)
    80003948:	f84a                	sd	s2,48(sp)
    8000394a:	f44e                	sd	s3,40(sp)
    8000394c:	f052                	sd	s4,32(sp)
    8000394e:	ec56                	sd	s5,24(sp)
    80003950:	e85a                	sd	s6,16(sp)
    80003952:	e45e                	sd	s7,8(sp)
    80003954:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003956:	0001c717          	auipc	a4,0x1c
    8000395a:	11e72703          	lw	a4,286(a4) # 8001fa74 <sb+0xc>
    8000395e:	4785                	li	a5,1
    80003960:	04e7fa63          	bgeu	a5,a4,800039b4 <ialloc+0x74>
    80003964:	8aaa                	mv	s5,a0
    80003966:	8bae                	mv	s7,a1
    80003968:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000396a:	0001ca17          	auipc	s4,0x1c
    8000396e:	0fea0a13          	addi	s4,s4,254 # 8001fa68 <sb>
    80003972:	00048b1b          	sext.w	s6,s1
    80003976:	0044d793          	srli	a5,s1,0x4
    8000397a:	018a2583          	lw	a1,24(s4)
    8000397e:	9dbd                	addw	a1,a1,a5
    80003980:	8556                	mv	a0,s5
    80003982:	00000097          	auipc	ra,0x0
    80003986:	940080e7          	jalr	-1728(ra) # 800032c2 <bread>
    8000398a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000398c:	05850993          	addi	s3,a0,88
    80003990:	00f4f793          	andi	a5,s1,15
    80003994:	079a                	slli	a5,a5,0x6
    80003996:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003998:	00099783          	lh	a5,0(s3)
    8000399c:	c3a1                	beqz	a5,800039dc <ialloc+0x9c>
    brelse(bp);
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	a54080e7          	jalr	-1452(ra) # 800033f2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039a6:	0485                	addi	s1,s1,1
    800039a8:	00ca2703          	lw	a4,12(s4)
    800039ac:	0004879b          	sext.w	a5,s1
    800039b0:	fce7e1e3          	bltu	a5,a4,80003972 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800039b4:	00005517          	auipc	a0,0x5
    800039b8:	c2c50513          	addi	a0,a0,-980 # 800085e0 <syscalls+0x180>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	bcc080e7          	jalr	-1076(ra) # 80000588 <printf>
  return 0;
    800039c4:	4501                	li	a0,0
}
    800039c6:	60a6                	ld	ra,72(sp)
    800039c8:	6406                	ld	s0,64(sp)
    800039ca:	74e2                	ld	s1,56(sp)
    800039cc:	7942                	ld	s2,48(sp)
    800039ce:	79a2                	ld	s3,40(sp)
    800039d0:	7a02                	ld	s4,32(sp)
    800039d2:	6ae2                	ld	s5,24(sp)
    800039d4:	6b42                	ld	s6,16(sp)
    800039d6:	6ba2                	ld	s7,8(sp)
    800039d8:	6161                	addi	sp,sp,80
    800039da:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800039dc:	04000613          	li	a2,64
    800039e0:	4581                	li	a1,0
    800039e2:	854e                	mv	a0,s3
    800039e4:	ffffd097          	auipc	ra,0xffffd
    800039e8:	2ee080e7          	jalr	750(ra) # 80000cd2 <memset>
      dip->type = type;
    800039ec:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039f0:	854a                	mv	a0,s2
    800039f2:	00001097          	auipc	ra,0x1
    800039f6:	c84080e7          	jalr	-892(ra) # 80004676 <log_write>
      brelse(bp);
    800039fa:	854a                	mv	a0,s2
    800039fc:	00000097          	auipc	ra,0x0
    80003a00:	9f6080e7          	jalr	-1546(ra) # 800033f2 <brelse>
      return iget(dev, inum);
    80003a04:	85da                	mv	a1,s6
    80003a06:	8556                	mv	a0,s5
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	d9c080e7          	jalr	-612(ra) # 800037a4 <iget>
    80003a10:	bf5d                	j	800039c6 <ialloc+0x86>

0000000080003a12 <iupdate>:
{
    80003a12:	1101                	addi	sp,sp,-32
    80003a14:	ec06                	sd	ra,24(sp)
    80003a16:	e822                	sd	s0,16(sp)
    80003a18:	e426                	sd	s1,8(sp)
    80003a1a:	e04a                	sd	s2,0(sp)
    80003a1c:	1000                	addi	s0,sp,32
    80003a1e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a20:	415c                	lw	a5,4(a0)
    80003a22:	0047d79b          	srliw	a5,a5,0x4
    80003a26:	0001c597          	auipc	a1,0x1c
    80003a2a:	05a5a583          	lw	a1,90(a1) # 8001fa80 <sb+0x18>
    80003a2e:	9dbd                	addw	a1,a1,a5
    80003a30:	4108                	lw	a0,0(a0)
    80003a32:	00000097          	auipc	ra,0x0
    80003a36:	890080e7          	jalr	-1904(ra) # 800032c2 <bread>
    80003a3a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a3c:	05850793          	addi	a5,a0,88
    80003a40:	40c8                	lw	a0,4(s1)
    80003a42:	893d                	andi	a0,a0,15
    80003a44:	051a                	slli	a0,a0,0x6
    80003a46:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a48:	04449703          	lh	a4,68(s1)
    80003a4c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a50:	04649703          	lh	a4,70(s1)
    80003a54:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a58:	04849703          	lh	a4,72(s1)
    80003a5c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a60:	04a49703          	lh	a4,74(s1)
    80003a64:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003a68:	44f8                	lw	a4,76(s1)
    80003a6a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a6c:	03400613          	li	a2,52
    80003a70:	05048593          	addi	a1,s1,80
    80003a74:	0531                	addi	a0,a0,12
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	2b8080e7          	jalr	696(ra) # 80000d2e <memmove>
  log_write(bp);
    80003a7e:	854a                	mv	a0,s2
    80003a80:	00001097          	auipc	ra,0x1
    80003a84:	bf6080e7          	jalr	-1034(ra) # 80004676 <log_write>
  brelse(bp);
    80003a88:	854a                	mv	a0,s2
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	968080e7          	jalr	-1688(ra) # 800033f2 <brelse>
}
    80003a92:	60e2                	ld	ra,24(sp)
    80003a94:	6442                	ld	s0,16(sp)
    80003a96:	64a2                	ld	s1,8(sp)
    80003a98:	6902                	ld	s2,0(sp)
    80003a9a:	6105                	addi	sp,sp,32
    80003a9c:	8082                	ret

0000000080003a9e <idup>:
{
    80003a9e:	1101                	addi	sp,sp,-32
    80003aa0:	ec06                	sd	ra,24(sp)
    80003aa2:	e822                	sd	s0,16(sp)
    80003aa4:	e426                	sd	s1,8(sp)
    80003aa6:	1000                	addi	s0,sp,32
    80003aa8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aaa:	0001c517          	auipc	a0,0x1c
    80003aae:	fde50513          	addi	a0,a0,-34 # 8001fa88 <itable>
    80003ab2:	ffffd097          	auipc	ra,0xffffd
    80003ab6:	124080e7          	jalr	292(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003aba:	449c                	lw	a5,8(s1)
    80003abc:	2785                	addiw	a5,a5,1
    80003abe:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ac0:	0001c517          	auipc	a0,0x1c
    80003ac4:	fc850513          	addi	a0,a0,-56 # 8001fa88 <itable>
    80003ac8:	ffffd097          	auipc	ra,0xffffd
    80003acc:	1c2080e7          	jalr	450(ra) # 80000c8a <release>
}
    80003ad0:	8526                	mv	a0,s1
    80003ad2:	60e2                	ld	ra,24(sp)
    80003ad4:	6442                	ld	s0,16(sp)
    80003ad6:	64a2                	ld	s1,8(sp)
    80003ad8:	6105                	addi	sp,sp,32
    80003ada:	8082                	ret

0000000080003adc <ilock>:
{
    80003adc:	1101                	addi	sp,sp,-32
    80003ade:	ec06                	sd	ra,24(sp)
    80003ae0:	e822                	sd	s0,16(sp)
    80003ae2:	e426                	sd	s1,8(sp)
    80003ae4:	e04a                	sd	s2,0(sp)
    80003ae6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ae8:	c115                	beqz	a0,80003b0c <ilock+0x30>
    80003aea:	84aa                	mv	s1,a0
    80003aec:	451c                	lw	a5,8(a0)
    80003aee:	00f05f63          	blez	a5,80003b0c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003af2:	0541                	addi	a0,a0,16
    80003af4:	00001097          	auipc	ra,0x1
    80003af8:	ca2080e7          	jalr	-862(ra) # 80004796 <acquiresleep>
  if(ip->valid == 0){
    80003afc:	40bc                	lw	a5,64(s1)
    80003afe:	cf99                	beqz	a5,80003b1c <ilock+0x40>
}
    80003b00:	60e2                	ld	ra,24(sp)
    80003b02:	6442                	ld	s0,16(sp)
    80003b04:	64a2                	ld	s1,8(sp)
    80003b06:	6902                	ld	s2,0(sp)
    80003b08:	6105                	addi	sp,sp,32
    80003b0a:	8082                	ret
    panic("ilock");
    80003b0c:	00005517          	auipc	a0,0x5
    80003b10:	aec50513          	addi	a0,a0,-1300 # 800085f8 <syscalls+0x198>
    80003b14:	ffffd097          	auipc	ra,0xffffd
    80003b18:	a2a080e7          	jalr	-1494(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b1c:	40dc                	lw	a5,4(s1)
    80003b1e:	0047d79b          	srliw	a5,a5,0x4
    80003b22:	0001c597          	auipc	a1,0x1c
    80003b26:	f5e5a583          	lw	a1,-162(a1) # 8001fa80 <sb+0x18>
    80003b2a:	9dbd                	addw	a1,a1,a5
    80003b2c:	4088                	lw	a0,0(s1)
    80003b2e:	fffff097          	auipc	ra,0xfffff
    80003b32:	794080e7          	jalr	1940(ra) # 800032c2 <bread>
    80003b36:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b38:	05850593          	addi	a1,a0,88
    80003b3c:	40dc                	lw	a5,4(s1)
    80003b3e:	8bbd                	andi	a5,a5,15
    80003b40:	079a                	slli	a5,a5,0x6
    80003b42:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b44:	00059783          	lh	a5,0(a1)
    80003b48:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b4c:	00259783          	lh	a5,2(a1)
    80003b50:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b54:	00459783          	lh	a5,4(a1)
    80003b58:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b5c:	00659783          	lh	a5,6(a1)
    80003b60:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b64:	459c                	lw	a5,8(a1)
    80003b66:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b68:	03400613          	li	a2,52
    80003b6c:	05b1                	addi	a1,a1,12
    80003b6e:	05048513          	addi	a0,s1,80
    80003b72:	ffffd097          	auipc	ra,0xffffd
    80003b76:	1bc080e7          	jalr	444(ra) # 80000d2e <memmove>
    brelse(bp);
    80003b7a:	854a                	mv	a0,s2
    80003b7c:	00000097          	auipc	ra,0x0
    80003b80:	876080e7          	jalr	-1930(ra) # 800033f2 <brelse>
    ip->valid = 1;
    80003b84:	4785                	li	a5,1
    80003b86:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b88:	04449783          	lh	a5,68(s1)
    80003b8c:	fbb5                	bnez	a5,80003b00 <ilock+0x24>
      panic("ilock: no type");
    80003b8e:	00005517          	auipc	a0,0x5
    80003b92:	a7250513          	addi	a0,a0,-1422 # 80008600 <syscalls+0x1a0>
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	9a8080e7          	jalr	-1624(ra) # 8000053e <panic>

0000000080003b9e <iunlock>:
{
    80003b9e:	1101                	addi	sp,sp,-32
    80003ba0:	ec06                	sd	ra,24(sp)
    80003ba2:	e822                	sd	s0,16(sp)
    80003ba4:	e426                	sd	s1,8(sp)
    80003ba6:	e04a                	sd	s2,0(sp)
    80003ba8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003baa:	c905                	beqz	a0,80003bda <iunlock+0x3c>
    80003bac:	84aa                	mv	s1,a0
    80003bae:	01050913          	addi	s2,a0,16
    80003bb2:	854a                	mv	a0,s2
    80003bb4:	00001097          	auipc	ra,0x1
    80003bb8:	c7c080e7          	jalr	-900(ra) # 80004830 <holdingsleep>
    80003bbc:	cd19                	beqz	a0,80003bda <iunlock+0x3c>
    80003bbe:	449c                	lw	a5,8(s1)
    80003bc0:	00f05d63          	blez	a5,80003bda <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bc4:	854a                	mv	a0,s2
    80003bc6:	00001097          	auipc	ra,0x1
    80003bca:	c26080e7          	jalr	-986(ra) # 800047ec <releasesleep>
}
    80003bce:	60e2                	ld	ra,24(sp)
    80003bd0:	6442                	ld	s0,16(sp)
    80003bd2:	64a2                	ld	s1,8(sp)
    80003bd4:	6902                	ld	s2,0(sp)
    80003bd6:	6105                	addi	sp,sp,32
    80003bd8:	8082                	ret
    panic("iunlock");
    80003bda:	00005517          	auipc	a0,0x5
    80003bde:	a3650513          	addi	a0,a0,-1482 # 80008610 <syscalls+0x1b0>
    80003be2:	ffffd097          	auipc	ra,0xffffd
    80003be6:	95c080e7          	jalr	-1700(ra) # 8000053e <panic>

0000000080003bea <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003bea:	7179                	addi	sp,sp,-48
    80003bec:	f406                	sd	ra,40(sp)
    80003bee:	f022                	sd	s0,32(sp)
    80003bf0:	ec26                	sd	s1,24(sp)
    80003bf2:	e84a                	sd	s2,16(sp)
    80003bf4:	e44e                	sd	s3,8(sp)
    80003bf6:	e052                	sd	s4,0(sp)
    80003bf8:	1800                	addi	s0,sp,48
    80003bfa:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003bfc:	05050493          	addi	s1,a0,80
    80003c00:	08050913          	addi	s2,a0,128
    80003c04:	a021                	j	80003c0c <itrunc+0x22>
    80003c06:	0491                	addi	s1,s1,4
    80003c08:	01248d63          	beq	s1,s2,80003c22 <itrunc+0x38>
    if(ip->addrs[i]){
    80003c0c:	408c                	lw	a1,0(s1)
    80003c0e:	dde5                	beqz	a1,80003c06 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c10:	0009a503          	lw	a0,0(s3)
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	8f4080e7          	jalr	-1804(ra) # 80003508 <bfree>
      ip->addrs[i] = 0;
    80003c1c:	0004a023          	sw	zero,0(s1)
    80003c20:	b7dd                	j	80003c06 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c22:	0809a583          	lw	a1,128(s3)
    80003c26:	e185                	bnez	a1,80003c46 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c28:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c2c:	854e                	mv	a0,s3
    80003c2e:	00000097          	auipc	ra,0x0
    80003c32:	de4080e7          	jalr	-540(ra) # 80003a12 <iupdate>
}
    80003c36:	70a2                	ld	ra,40(sp)
    80003c38:	7402                	ld	s0,32(sp)
    80003c3a:	64e2                	ld	s1,24(sp)
    80003c3c:	6942                	ld	s2,16(sp)
    80003c3e:	69a2                	ld	s3,8(sp)
    80003c40:	6a02                	ld	s4,0(sp)
    80003c42:	6145                	addi	sp,sp,48
    80003c44:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c46:	0009a503          	lw	a0,0(s3)
    80003c4a:	fffff097          	auipc	ra,0xfffff
    80003c4e:	678080e7          	jalr	1656(ra) # 800032c2 <bread>
    80003c52:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c54:	05850493          	addi	s1,a0,88
    80003c58:	45850913          	addi	s2,a0,1112
    80003c5c:	a021                	j	80003c64 <itrunc+0x7a>
    80003c5e:	0491                	addi	s1,s1,4
    80003c60:	01248b63          	beq	s1,s2,80003c76 <itrunc+0x8c>
      if(a[j])
    80003c64:	408c                	lw	a1,0(s1)
    80003c66:	dde5                	beqz	a1,80003c5e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c68:	0009a503          	lw	a0,0(s3)
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	89c080e7          	jalr	-1892(ra) # 80003508 <bfree>
    80003c74:	b7ed                	j	80003c5e <itrunc+0x74>
    brelse(bp);
    80003c76:	8552                	mv	a0,s4
    80003c78:	fffff097          	auipc	ra,0xfffff
    80003c7c:	77a080e7          	jalr	1914(ra) # 800033f2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c80:	0809a583          	lw	a1,128(s3)
    80003c84:	0009a503          	lw	a0,0(s3)
    80003c88:	00000097          	auipc	ra,0x0
    80003c8c:	880080e7          	jalr	-1920(ra) # 80003508 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c90:	0809a023          	sw	zero,128(s3)
    80003c94:	bf51                	j	80003c28 <itrunc+0x3e>

0000000080003c96 <iput>:
{
    80003c96:	1101                	addi	sp,sp,-32
    80003c98:	ec06                	sd	ra,24(sp)
    80003c9a:	e822                	sd	s0,16(sp)
    80003c9c:	e426                	sd	s1,8(sp)
    80003c9e:	e04a                	sd	s2,0(sp)
    80003ca0:	1000                	addi	s0,sp,32
    80003ca2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ca4:	0001c517          	auipc	a0,0x1c
    80003ca8:	de450513          	addi	a0,a0,-540 # 8001fa88 <itable>
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	f2a080e7          	jalr	-214(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cb4:	4498                	lw	a4,8(s1)
    80003cb6:	4785                	li	a5,1
    80003cb8:	02f70363          	beq	a4,a5,80003cde <iput+0x48>
  ip->ref--;
    80003cbc:	449c                	lw	a5,8(s1)
    80003cbe:	37fd                	addiw	a5,a5,-1
    80003cc0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cc2:	0001c517          	auipc	a0,0x1c
    80003cc6:	dc650513          	addi	a0,a0,-570 # 8001fa88 <itable>
    80003cca:	ffffd097          	auipc	ra,0xffffd
    80003cce:	fc0080e7          	jalr	-64(ra) # 80000c8a <release>
}
    80003cd2:	60e2                	ld	ra,24(sp)
    80003cd4:	6442                	ld	s0,16(sp)
    80003cd6:	64a2                	ld	s1,8(sp)
    80003cd8:	6902                	ld	s2,0(sp)
    80003cda:	6105                	addi	sp,sp,32
    80003cdc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cde:	40bc                	lw	a5,64(s1)
    80003ce0:	dff1                	beqz	a5,80003cbc <iput+0x26>
    80003ce2:	04a49783          	lh	a5,74(s1)
    80003ce6:	fbf9                	bnez	a5,80003cbc <iput+0x26>
    acquiresleep(&ip->lock);
    80003ce8:	01048913          	addi	s2,s1,16
    80003cec:	854a                	mv	a0,s2
    80003cee:	00001097          	auipc	ra,0x1
    80003cf2:	aa8080e7          	jalr	-1368(ra) # 80004796 <acquiresleep>
    release(&itable.lock);
    80003cf6:	0001c517          	auipc	a0,0x1c
    80003cfa:	d9250513          	addi	a0,a0,-622 # 8001fa88 <itable>
    80003cfe:	ffffd097          	auipc	ra,0xffffd
    80003d02:	f8c080e7          	jalr	-116(ra) # 80000c8a <release>
    itrunc(ip);
    80003d06:	8526                	mv	a0,s1
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	ee2080e7          	jalr	-286(ra) # 80003bea <itrunc>
    ip->type = 0;
    80003d10:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d14:	8526                	mv	a0,s1
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	cfc080e7          	jalr	-772(ra) # 80003a12 <iupdate>
    ip->valid = 0;
    80003d1e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d22:	854a                	mv	a0,s2
    80003d24:	00001097          	auipc	ra,0x1
    80003d28:	ac8080e7          	jalr	-1336(ra) # 800047ec <releasesleep>
    acquire(&itable.lock);
    80003d2c:	0001c517          	auipc	a0,0x1c
    80003d30:	d5c50513          	addi	a0,a0,-676 # 8001fa88 <itable>
    80003d34:	ffffd097          	auipc	ra,0xffffd
    80003d38:	ea2080e7          	jalr	-350(ra) # 80000bd6 <acquire>
    80003d3c:	b741                	j	80003cbc <iput+0x26>

0000000080003d3e <iunlockput>:
{
    80003d3e:	1101                	addi	sp,sp,-32
    80003d40:	ec06                	sd	ra,24(sp)
    80003d42:	e822                	sd	s0,16(sp)
    80003d44:	e426                	sd	s1,8(sp)
    80003d46:	1000                	addi	s0,sp,32
    80003d48:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	e54080e7          	jalr	-428(ra) # 80003b9e <iunlock>
  iput(ip);
    80003d52:	8526                	mv	a0,s1
    80003d54:	00000097          	auipc	ra,0x0
    80003d58:	f42080e7          	jalr	-190(ra) # 80003c96 <iput>
}
    80003d5c:	60e2                	ld	ra,24(sp)
    80003d5e:	6442                	ld	s0,16(sp)
    80003d60:	64a2                	ld	s1,8(sp)
    80003d62:	6105                	addi	sp,sp,32
    80003d64:	8082                	ret

0000000080003d66 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d66:	1141                	addi	sp,sp,-16
    80003d68:	e422                	sd	s0,8(sp)
    80003d6a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d6c:	411c                	lw	a5,0(a0)
    80003d6e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d70:	415c                	lw	a5,4(a0)
    80003d72:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d74:	04451783          	lh	a5,68(a0)
    80003d78:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d7c:	04a51783          	lh	a5,74(a0)
    80003d80:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d84:	04c56783          	lwu	a5,76(a0)
    80003d88:	e99c                	sd	a5,16(a1)
}
    80003d8a:	6422                	ld	s0,8(sp)
    80003d8c:	0141                	addi	sp,sp,16
    80003d8e:	8082                	ret

0000000080003d90 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d90:	457c                	lw	a5,76(a0)
    80003d92:	0ed7e963          	bltu	a5,a3,80003e84 <readi+0xf4>
{
    80003d96:	7159                	addi	sp,sp,-112
    80003d98:	f486                	sd	ra,104(sp)
    80003d9a:	f0a2                	sd	s0,96(sp)
    80003d9c:	eca6                	sd	s1,88(sp)
    80003d9e:	e8ca                	sd	s2,80(sp)
    80003da0:	e4ce                	sd	s3,72(sp)
    80003da2:	e0d2                	sd	s4,64(sp)
    80003da4:	fc56                	sd	s5,56(sp)
    80003da6:	f85a                	sd	s6,48(sp)
    80003da8:	f45e                	sd	s7,40(sp)
    80003daa:	f062                	sd	s8,32(sp)
    80003dac:	ec66                	sd	s9,24(sp)
    80003dae:	e86a                	sd	s10,16(sp)
    80003db0:	e46e                	sd	s11,8(sp)
    80003db2:	1880                	addi	s0,sp,112
    80003db4:	8b2a                	mv	s6,a0
    80003db6:	8bae                	mv	s7,a1
    80003db8:	8a32                	mv	s4,a2
    80003dba:	84b6                	mv	s1,a3
    80003dbc:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003dbe:	9f35                	addw	a4,a4,a3
    return 0;
    80003dc0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003dc2:	0ad76063          	bltu	a4,a3,80003e62 <readi+0xd2>
  if(off + n > ip->size)
    80003dc6:	00e7f463          	bgeu	a5,a4,80003dce <readi+0x3e>
    n = ip->size - off;
    80003dca:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dce:	0a0a8963          	beqz	s5,80003e80 <readi+0xf0>
    80003dd2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dd4:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003dd8:	5c7d                	li	s8,-1
    80003dda:	a82d                	j	80003e14 <readi+0x84>
    80003ddc:	020d1d93          	slli	s11,s10,0x20
    80003de0:	020ddd93          	srli	s11,s11,0x20
    80003de4:	05890793          	addi	a5,s2,88
    80003de8:	86ee                	mv	a3,s11
    80003dea:	963e                	add	a2,a2,a5
    80003dec:	85d2                	mv	a1,s4
    80003dee:	855e                	mv	a0,s7
    80003df0:	ffffe097          	auipc	ra,0xffffe
    80003df4:	7a4080e7          	jalr	1956(ra) # 80002594 <either_copyout>
    80003df8:	05850d63          	beq	a0,s8,80003e52 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003dfc:	854a                	mv	a0,s2
    80003dfe:	fffff097          	auipc	ra,0xfffff
    80003e02:	5f4080e7          	jalr	1524(ra) # 800033f2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e06:	013d09bb          	addw	s3,s10,s3
    80003e0a:	009d04bb          	addw	s1,s10,s1
    80003e0e:	9a6e                	add	s4,s4,s11
    80003e10:	0559f763          	bgeu	s3,s5,80003e5e <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003e14:	00a4d59b          	srliw	a1,s1,0xa
    80003e18:	855a                	mv	a0,s6
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	8a2080e7          	jalr	-1886(ra) # 800036bc <bmap>
    80003e22:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e26:	cd85                	beqz	a1,80003e5e <readi+0xce>
    bp = bread(ip->dev, addr);
    80003e28:	000b2503          	lw	a0,0(s6)
    80003e2c:	fffff097          	auipc	ra,0xfffff
    80003e30:	496080e7          	jalr	1174(ra) # 800032c2 <bread>
    80003e34:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e36:	3ff4f613          	andi	a2,s1,1023
    80003e3a:	40cc87bb          	subw	a5,s9,a2
    80003e3e:	413a873b          	subw	a4,s5,s3
    80003e42:	8d3e                	mv	s10,a5
    80003e44:	2781                	sext.w	a5,a5
    80003e46:	0007069b          	sext.w	a3,a4
    80003e4a:	f8f6f9e3          	bgeu	a3,a5,80003ddc <readi+0x4c>
    80003e4e:	8d3a                	mv	s10,a4
    80003e50:	b771                	j	80003ddc <readi+0x4c>
      brelse(bp);
    80003e52:	854a                	mv	a0,s2
    80003e54:	fffff097          	auipc	ra,0xfffff
    80003e58:	59e080e7          	jalr	1438(ra) # 800033f2 <brelse>
      tot = -1;
    80003e5c:	59fd                	li	s3,-1
  }
  return tot;
    80003e5e:	0009851b          	sext.w	a0,s3
}
    80003e62:	70a6                	ld	ra,104(sp)
    80003e64:	7406                	ld	s0,96(sp)
    80003e66:	64e6                	ld	s1,88(sp)
    80003e68:	6946                	ld	s2,80(sp)
    80003e6a:	69a6                	ld	s3,72(sp)
    80003e6c:	6a06                	ld	s4,64(sp)
    80003e6e:	7ae2                	ld	s5,56(sp)
    80003e70:	7b42                	ld	s6,48(sp)
    80003e72:	7ba2                	ld	s7,40(sp)
    80003e74:	7c02                	ld	s8,32(sp)
    80003e76:	6ce2                	ld	s9,24(sp)
    80003e78:	6d42                	ld	s10,16(sp)
    80003e7a:	6da2                	ld	s11,8(sp)
    80003e7c:	6165                	addi	sp,sp,112
    80003e7e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e80:	89d6                	mv	s3,s5
    80003e82:	bff1                	j	80003e5e <readi+0xce>
    return 0;
    80003e84:	4501                	li	a0,0
}
    80003e86:	8082                	ret

0000000080003e88 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e88:	457c                	lw	a5,76(a0)
    80003e8a:	10d7e863          	bltu	a5,a3,80003f9a <writei+0x112>
{
    80003e8e:	7159                	addi	sp,sp,-112
    80003e90:	f486                	sd	ra,104(sp)
    80003e92:	f0a2                	sd	s0,96(sp)
    80003e94:	eca6                	sd	s1,88(sp)
    80003e96:	e8ca                	sd	s2,80(sp)
    80003e98:	e4ce                	sd	s3,72(sp)
    80003e9a:	e0d2                	sd	s4,64(sp)
    80003e9c:	fc56                	sd	s5,56(sp)
    80003e9e:	f85a                	sd	s6,48(sp)
    80003ea0:	f45e                	sd	s7,40(sp)
    80003ea2:	f062                	sd	s8,32(sp)
    80003ea4:	ec66                	sd	s9,24(sp)
    80003ea6:	e86a                	sd	s10,16(sp)
    80003ea8:	e46e                	sd	s11,8(sp)
    80003eaa:	1880                	addi	s0,sp,112
    80003eac:	8aaa                	mv	s5,a0
    80003eae:	8bae                	mv	s7,a1
    80003eb0:	8a32                	mv	s4,a2
    80003eb2:	8936                	mv	s2,a3
    80003eb4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003eb6:	00e687bb          	addw	a5,a3,a4
    80003eba:	0ed7e263          	bltu	a5,a3,80003f9e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ebe:	00043737          	lui	a4,0x43
    80003ec2:	0ef76063          	bltu	a4,a5,80003fa2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ec6:	0c0b0863          	beqz	s6,80003f96 <writei+0x10e>
    80003eca:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ecc:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ed0:	5c7d                	li	s8,-1
    80003ed2:	a091                	j	80003f16 <writei+0x8e>
    80003ed4:	020d1d93          	slli	s11,s10,0x20
    80003ed8:	020ddd93          	srli	s11,s11,0x20
    80003edc:	05848793          	addi	a5,s1,88
    80003ee0:	86ee                	mv	a3,s11
    80003ee2:	8652                	mv	a2,s4
    80003ee4:	85de                	mv	a1,s7
    80003ee6:	953e                	add	a0,a0,a5
    80003ee8:	ffffe097          	auipc	ra,0xffffe
    80003eec:	702080e7          	jalr	1794(ra) # 800025ea <either_copyin>
    80003ef0:	07850263          	beq	a0,s8,80003f54 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ef4:	8526                	mv	a0,s1
    80003ef6:	00000097          	auipc	ra,0x0
    80003efa:	780080e7          	jalr	1920(ra) # 80004676 <log_write>
    brelse(bp);
    80003efe:	8526                	mv	a0,s1
    80003f00:	fffff097          	auipc	ra,0xfffff
    80003f04:	4f2080e7          	jalr	1266(ra) # 800033f2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f08:	013d09bb          	addw	s3,s10,s3
    80003f0c:	012d093b          	addw	s2,s10,s2
    80003f10:	9a6e                	add	s4,s4,s11
    80003f12:	0569f663          	bgeu	s3,s6,80003f5e <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003f16:	00a9559b          	srliw	a1,s2,0xa
    80003f1a:	8556                	mv	a0,s5
    80003f1c:	fffff097          	auipc	ra,0xfffff
    80003f20:	7a0080e7          	jalr	1952(ra) # 800036bc <bmap>
    80003f24:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f28:	c99d                	beqz	a1,80003f5e <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003f2a:	000aa503          	lw	a0,0(s5)
    80003f2e:	fffff097          	auipc	ra,0xfffff
    80003f32:	394080e7          	jalr	916(ra) # 800032c2 <bread>
    80003f36:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f38:	3ff97513          	andi	a0,s2,1023
    80003f3c:	40ac87bb          	subw	a5,s9,a0
    80003f40:	413b073b          	subw	a4,s6,s3
    80003f44:	8d3e                	mv	s10,a5
    80003f46:	2781                	sext.w	a5,a5
    80003f48:	0007069b          	sext.w	a3,a4
    80003f4c:	f8f6f4e3          	bgeu	a3,a5,80003ed4 <writei+0x4c>
    80003f50:	8d3a                	mv	s10,a4
    80003f52:	b749                	j	80003ed4 <writei+0x4c>
      brelse(bp);
    80003f54:	8526                	mv	a0,s1
    80003f56:	fffff097          	auipc	ra,0xfffff
    80003f5a:	49c080e7          	jalr	1180(ra) # 800033f2 <brelse>
  }

  if(off > ip->size)
    80003f5e:	04caa783          	lw	a5,76(s5)
    80003f62:	0127f463          	bgeu	a5,s2,80003f6a <writei+0xe2>
    ip->size = off;
    80003f66:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f6a:	8556                	mv	a0,s5
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	aa6080e7          	jalr	-1370(ra) # 80003a12 <iupdate>

  return tot;
    80003f74:	0009851b          	sext.w	a0,s3
}
    80003f78:	70a6                	ld	ra,104(sp)
    80003f7a:	7406                	ld	s0,96(sp)
    80003f7c:	64e6                	ld	s1,88(sp)
    80003f7e:	6946                	ld	s2,80(sp)
    80003f80:	69a6                	ld	s3,72(sp)
    80003f82:	6a06                	ld	s4,64(sp)
    80003f84:	7ae2                	ld	s5,56(sp)
    80003f86:	7b42                	ld	s6,48(sp)
    80003f88:	7ba2                	ld	s7,40(sp)
    80003f8a:	7c02                	ld	s8,32(sp)
    80003f8c:	6ce2                	ld	s9,24(sp)
    80003f8e:	6d42                	ld	s10,16(sp)
    80003f90:	6da2                	ld	s11,8(sp)
    80003f92:	6165                	addi	sp,sp,112
    80003f94:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f96:	89da                	mv	s3,s6
    80003f98:	bfc9                	j	80003f6a <writei+0xe2>
    return -1;
    80003f9a:	557d                	li	a0,-1
}
    80003f9c:	8082                	ret
    return -1;
    80003f9e:	557d                	li	a0,-1
    80003fa0:	bfe1                	j	80003f78 <writei+0xf0>
    return -1;
    80003fa2:	557d                	li	a0,-1
    80003fa4:	bfd1                	j	80003f78 <writei+0xf0>

0000000080003fa6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fa6:	1141                	addi	sp,sp,-16
    80003fa8:	e406                	sd	ra,8(sp)
    80003faa:	e022                	sd	s0,0(sp)
    80003fac:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fae:	4639                	li	a2,14
    80003fb0:	ffffd097          	auipc	ra,0xffffd
    80003fb4:	df2080e7          	jalr	-526(ra) # 80000da2 <strncmp>
}
    80003fb8:	60a2                	ld	ra,8(sp)
    80003fba:	6402                	ld	s0,0(sp)
    80003fbc:	0141                	addi	sp,sp,16
    80003fbe:	8082                	ret

0000000080003fc0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fc0:	7139                	addi	sp,sp,-64
    80003fc2:	fc06                	sd	ra,56(sp)
    80003fc4:	f822                	sd	s0,48(sp)
    80003fc6:	f426                	sd	s1,40(sp)
    80003fc8:	f04a                	sd	s2,32(sp)
    80003fca:	ec4e                	sd	s3,24(sp)
    80003fcc:	e852                	sd	s4,16(sp)
    80003fce:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fd0:	04451703          	lh	a4,68(a0)
    80003fd4:	4785                	li	a5,1
    80003fd6:	00f71a63          	bne	a4,a5,80003fea <dirlookup+0x2a>
    80003fda:	892a                	mv	s2,a0
    80003fdc:	89ae                	mv	s3,a1
    80003fde:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fe0:	457c                	lw	a5,76(a0)
    80003fe2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003fe4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fe6:	e79d                	bnez	a5,80004014 <dirlookup+0x54>
    80003fe8:	a8a5                	j	80004060 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003fea:	00004517          	auipc	a0,0x4
    80003fee:	62e50513          	addi	a0,a0,1582 # 80008618 <syscalls+0x1b8>
    80003ff2:	ffffc097          	auipc	ra,0xffffc
    80003ff6:	54c080e7          	jalr	1356(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003ffa:	00004517          	auipc	a0,0x4
    80003ffe:	63650513          	addi	a0,a0,1590 # 80008630 <syscalls+0x1d0>
    80004002:	ffffc097          	auipc	ra,0xffffc
    80004006:	53c080e7          	jalr	1340(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000400a:	24c1                	addiw	s1,s1,16
    8000400c:	04c92783          	lw	a5,76(s2)
    80004010:	04f4f763          	bgeu	s1,a5,8000405e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004014:	4741                	li	a4,16
    80004016:	86a6                	mv	a3,s1
    80004018:	fc040613          	addi	a2,s0,-64
    8000401c:	4581                	li	a1,0
    8000401e:	854a                	mv	a0,s2
    80004020:	00000097          	auipc	ra,0x0
    80004024:	d70080e7          	jalr	-656(ra) # 80003d90 <readi>
    80004028:	47c1                	li	a5,16
    8000402a:	fcf518e3          	bne	a0,a5,80003ffa <dirlookup+0x3a>
    if(de.inum == 0)
    8000402e:	fc045783          	lhu	a5,-64(s0)
    80004032:	dfe1                	beqz	a5,8000400a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004034:	fc240593          	addi	a1,s0,-62
    80004038:	854e                	mv	a0,s3
    8000403a:	00000097          	auipc	ra,0x0
    8000403e:	f6c080e7          	jalr	-148(ra) # 80003fa6 <namecmp>
    80004042:	f561                	bnez	a0,8000400a <dirlookup+0x4a>
      if(poff)
    80004044:	000a0463          	beqz	s4,8000404c <dirlookup+0x8c>
        *poff = off;
    80004048:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000404c:	fc045583          	lhu	a1,-64(s0)
    80004050:	00092503          	lw	a0,0(s2)
    80004054:	fffff097          	auipc	ra,0xfffff
    80004058:	750080e7          	jalr	1872(ra) # 800037a4 <iget>
    8000405c:	a011                	j	80004060 <dirlookup+0xa0>
  return 0;
    8000405e:	4501                	li	a0,0
}
    80004060:	70e2                	ld	ra,56(sp)
    80004062:	7442                	ld	s0,48(sp)
    80004064:	74a2                	ld	s1,40(sp)
    80004066:	7902                	ld	s2,32(sp)
    80004068:	69e2                	ld	s3,24(sp)
    8000406a:	6a42                	ld	s4,16(sp)
    8000406c:	6121                	addi	sp,sp,64
    8000406e:	8082                	ret

0000000080004070 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004070:	711d                	addi	sp,sp,-96
    80004072:	ec86                	sd	ra,88(sp)
    80004074:	e8a2                	sd	s0,80(sp)
    80004076:	e4a6                	sd	s1,72(sp)
    80004078:	e0ca                	sd	s2,64(sp)
    8000407a:	fc4e                	sd	s3,56(sp)
    8000407c:	f852                	sd	s4,48(sp)
    8000407e:	f456                	sd	s5,40(sp)
    80004080:	f05a                	sd	s6,32(sp)
    80004082:	ec5e                	sd	s7,24(sp)
    80004084:	e862                	sd	s8,16(sp)
    80004086:	e466                	sd	s9,8(sp)
    80004088:	1080                	addi	s0,sp,96
    8000408a:	84aa                	mv	s1,a0
    8000408c:	8aae                	mv	s5,a1
    8000408e:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004090:	00054703          	lbu	a4,0(a0)
    80004094:	02f00793          	li	a5,47
    80004098:	02f70363          	beq	a4,a5,800040be <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000409c:	ffffe097          	auipc	ra,0xffffe
    800040a0:	910080e7          	jalr	-1776(ra) # 800019ac <myproc>
    800040a4:	15053503          	ld	a0,336(a0)
    800040a8:	00000097          	auipc	ra,0x0
    800040ac:	9f6080e7          	jalr	-1546(ra) # 80003a9e <idup>
    800040b0:	89aa                	mv	s3,a0
  while(*path == '/')
    800040b2:	02f00913          	li	s2,47
  len = path - s;
    800040b6:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800040b8:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040ba:	4b85                	li	s7,1
    800040bc:	a865                	j	80004174 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800040be:	4585                	li	a1,1
    800040c0:	4505                	li	a0,1
    800040c2:	fffff097          	auipc	ra,0xfffff
    800040c6:	6e2080e7          	jalr	1762(ra) # 800037a4 <iget>
    800040ca:	89aa                	mv	s3,a0
    800040cc:	b7dd                	j	800040b2 <namex+0x42>
      iunlockput(ip);
    800040ce:	854e                	mv	a0,s3
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	c6e080e7          	jalr	-914(ra) # 80003d3e <iunlockput>
      return 0;
    800040d8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040da:	854e                	mv	a0,s3
    800040dc:	60e6                	ld	ra,88(sp)
    800040de:	6446                	ld	s0,80(sp)
    800040e0:	64a6                	ld	s1,72(sp)
    800040e2:	6906                	ld	s2,64(sp)
    800040e4:	79e2                	ld	s3,56(sp)
    800040e6:	7a42                	ld	s4,48(sp)
    800040e8:	7aa2                	ld	s5,40(sp)
    800040ea:	7b02                	ld	s6,32(sp)
    800040ec:	6be2                	ld	s7,24(sp)
    800040ee:	6c42                	ld	s8,16(sp)
    800040f0:	6ca2                	ld	s9,8(sp)
    800040f2:	6125                	addi	sp,sp,96
    800040f4:	8082                	ret
      iunlock(ip);
    800040f6:	854e                	mv	a0,s3
    800040f8:	00000097          	auipc	ra,0x0
    800040fc:	aa6080e7          	jalr	-1370(ra) # 80003b9e <iunlock>
      return ip;
    80004100:	bfe9                	j	800040da <namex+0x6a>
      iunlockput(ip);
    80004102:	854e                	mv	a0,s3
    80004104:	00000097          	auipc	ra,0x0
    80004108:	c3a080e7          	jalr	-966(ra) # 80003d3e <iunlockput>
      return 0;
    8000410c:	89e6                	mv	s3,s9
    8000410e:	b7f1                	j	800040da <namex+0x6a>
  len = path - s;
    80004110:	40b48633          	sub	a2,s1,a1
    80004114:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004118:	099c5463          	bge	s8,s9,800041a0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000411c:	4639                	li	a2,14
    8000411e:	8552                	mv	a0,s4
    80004120:	ffffd097          	auipc	ra,0xffffd
    80004124:	c0e080e7          	jalr	-1010(ra) # 80000d2e <memmove>
  while(*path == '/')
    80004128:	0004c783          	lbu	a5,0(s1)
    8000412c:	01279763          	bne	a5,s2,8000413a <namex+0xca>
    path++;
    80004130:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004132:	0004c783          	lbu	a5,0(s1)
    80004136:	ff278de3          	beq	a5,s2,80004130 <namex+0xc0>
    ilock(ip);
    8000413a:	854e                	mv	a0,s3
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	9a0080e7          	jalr	-1632(ra) # 80003adc <ilock>
    if(ip->type != T_DIR){
    80004144:	04499783          	lh	a5,68(s3)
    80004148:	f97793e3          	bne	a5,s7,800040ce <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000414c:	000a8563          	beqz	s5,80004156 <namex+0xe6>
    80004150:	0004c783          	lbu	a5,0(s1)
    80004154:	d3cd                	beqz	a5,800040f6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004156:	865a                	mv	a2,s6
    80004158:	85d2                	mv	a1,s4
    8000415a:	854e                	mv	a0,s3
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	e64080e7          	jalr	-412(ra) # 80003fc0 <dirlookup>
    80004164:	8caa                	mv	s9,a0
    80004166:	dd51                	beqz	a0,80004102 <namex+0x92>
    iunlockput(ip);
    80004168:	854e                	mv	a0,s3
    8000416a:	00000097          	auipc	ra,0x0
    8000416e:	bd4080e7          	jalr	-1068(ra) # 80003d3e <iunlockput>
    ip = next;
    80004172:	89e6                	mv	s3,s9
  while(*path == '/')
    80004174:	0004c783          	lbu	a5,0(s1)
    80004178:	05279763          	bne	a5,s2,800041c6 <namex+0x156>
    path++;
    8000417c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000417e:	0004c783          	lbu	a5,0(s1)
    80004182:	ff278de3          	beq	a5,s2,8000417c <namex+0x10c>
  if(*path == 0)
    80004186:	c79d                	beqz	a5,800041b4 <namex+0x144>
    path++;
    80004188:	85a6                	mv	a1,s1
  len = path - s;
    8000418a:	8cda                	mv	s9,s6
    8000418c:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000418e:	01278963          	beq	a5,s2,800041a0 <namex+0x130>
    80004192:	dfbd                	beqz	a5,80004110 <namex+0xa0>
    path++;
    80004194:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004196:	0004c783          	lbu	a5,0(s1)
    8000419a:	ff279ce3          	bne	a5,s2,80004192 <namex+0x122>
    8000419e:	bf8d                	j	80004110 <namex+0xa0>
    memmove(name, s, len);
    800041a0:	2601                	sext.w	a2,a2
    800041a2:	8552                	mv	a0,s4
    800041a4:	ffffd097          	auipc	ra,0xffffd
    800041a8:	b8a080e7          	jalr	-1142(ra) # 80000d2e <memmove>
    name[len] = 0;
    800041ac:	9cd2                	add	s9,s9,s4
    800041ae:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800041b2:	bf9d                	j	80004128 <namex+0xb8>
  if(nameiparent){
    800041b4:	f20a83e3          	beqz	s5,800040da <namex+0x6a>
    iput(ip);
    800041b8:	854e                	mv	a0,s3
    800041ba:	00000097          	auipc	ra,0x0
    800041be:	adc080e7          	jalr	-1316(ra) # 80003c96 <iput>
    return 0;
    800041c2:	4981                	li	s3,0
    800041c4:	bf19                	j	800040da <namex+0x6a>
  if(*path == 0)
    800041c6:	d7fd                	beqz	a5,800041b4 <namex+0x144>
  while(*path != '/' && *path != 0)
    800041c8:	0004c783          	lbu	a5,0(s1)
    800041cc:	85a6                	mv	a1,s1
    800041ce:	b7d1                	j	80004192 <namex+0x122>

00000000800041d0 <dirlink>:
{
    800041d0:	7139                	addi	sp,sp,-64
    800041d2:	fc06                	sd	ra,56(sp)
    800041d4:	f822                	sd	s0,48(sp)
    800041d6:	f426                	sd	s1,40(sp)
    800041d8:	f04a                	sd	s2,32(sp)
    800041da:	ec4e                	sd	s3,24(sp)
    800041dc:	e852                	sd	s4,16(sp)
    800041de:	0080                	addi	s0,sp,64
    800041e0:	892a                	mv	s2,a0
    800041e2:	8a2e                	mv	s4,a1
    800041e4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041e6:	4601                	li	a2,0
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	dd8080e7          	jalr	-552(ra) # 80003fc0 <dirlookup>
    800041f0:	e93d                	bnez	a0,80004266 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041f2:	04c92483          	lw	s1,76(s2)
    800041f6:	c49d                	beqz	s1,80004224 <dirlink+0x54>
    800041f8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041fa:	4741                	li	a4,16
    800041fc:	86a6                	mv	a3,s1
    800041fe:	fc040613          	addi	a2,s0,-64
    80004202:	4581                	li	a1,0
    80004204:	854a                	mv	a0,s2
    80004206:	00000097          	auipc	ra,0x0
    8000420a:	b8a080e7          	jalr	-1142(ra) # 80003d90 <readi>
    8000420e:	47c1                	li	a5,16
    80004210:	06f51163          	bne	a0,a5,80004272 <dirlink+0xa2>
    if(de.inum == 0)
    80004214:	fc045783          	lhu	a5,-64(s0)
    80004218:	c791                	beqz	a5,80004224 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000421a:	24c1                	addiw	s1,s1,16
    8000421c:	04c92783          	lw	a5,76(s2)
    80004220:	fcf4ede3          	bltu	s1,a5,800041fa <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004224:	4639                	li	a2,14
    80004226:	85d2                	mv	a1,s4
    80004228:	fc240513          	addi	a0,s0,-62
    8000422c:	ffffd097          	auipc	ra,0xffffd
    80004230:	bb2080e7          	jalr	-1102(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004234:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004238:	4741                	li	a4,16
    8000423a:	86a6                	mv	a3,s1
    8000423c:	fc040613          	addi	a2,s0,-64
    80004240:	4581                	li	a1,0
    80004242:	854a                	mv	a0,s2
    80004244:	00000097          	auipc	ra,0x0
    80004248:	c44080e7          	jalr	-956(ra) # 80003e88 <writei>
    8000424c:	1541                	addi	a0,a0,-16
    8000424e:	00a03533          	snez	a0,a0
    80004252:	40a00533          	neg	a0,a0
}
    80004256:	70e2                	ld	ra,56(sp)
    80004258:	7442                	ld	s0,48(sp)
    8000425a:	74a2                	ld	s1,40(sp)
    8000425c:	7902                	ld	s2,32(sp)
    8000425e:	69e2                	ld	s3,24(sp)
    80004260:	6a42                	ld	s4,16(sp)
    80004262:	6121                	addi	sp,sp,64
    80004264:	8082                	ret
    iput(ip);
    80004266:	00000097          	auipc	ra,0x0
    8000426a:	a30080e7          	jalr	-1488(ra) # 80003c96 <iput>
    return -1;
    8000426e:	557d                	li	a0,-1
    80004270:	b7dd                	j	80004256 <dirlink+0x86>
      panic("dirlink read");
    80004272:	00004517          	auipc	a0,0x4
    80004276:	3ce50513          	addi	a0,a0,974 # 80008640 <syscalls+0x1e0>
    8000427a:	ffffc097          	auipc	ra,0xffffc
    8000427e:	2c4080e7          	jalr	708(ra) # 8000053e <panic>

0000000080004282 <namei>:

struct inode*
namei(char *path)
{
    80004282:	1101                	addi	sp,sp,-32
    80004284:	ec06                	sd	ra,24(sp)
    80004286:	e822                	sd	s0,16(sp)
    80004288:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000428a:	fe040613          	addi	a2,s0,-32
    8000428e:	4581                	li	a1,0
    80004290:	00000097          	auipc	ra,0x0
    80004294:	de0080e7          	jalr	-544(ra) # 80004070 <namex>
}
    80004298:	60e2                	ld	ra,24(sp)
    8000429a:	6442                	ld	s0,16(sp)
    8000429c:	6105                	addi	sp,sp,32
    8000429e:	8082                	ret

00000000800042a0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042a0:	1141                	addi	sp,sp,-16
    800042a2:	e406                	sd	ra,8(sp)
    800042a4:	e022                	sd	s0,0(sp)
    800042a6:	0800                	addi	s0,sp,16
    800042a8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042aa:	4585                	li	a1,1
    800042ac:	00000097          	auipc	ra,0x0
    800042b0:	dc4080e7          	jalr	-572(ra) # 80004070 <namex>
}
    800042b4:	60a2                	ld	ra,8(sp)
    800042b6:	6402                	ld	s0,0(sp)
    800042b8:	0141                	addi	sp,sp,16
    800042ba:	8082                	ret

00000000800042bc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042bc:	1101                	addi	sp,sp,-32
    800042be:	ec06                	sd	ra,24(sp)
    800042c0:	e822                	sd	s0,16(sp)
    800042c2:	e426                	sd	s1,8(sp)
    800042c4:	e04a                	sd	s2,0(sp)
    800042c6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042c8:	0001d917          	auipc	s2,0x1d
    800042cc:	26890913          	addi	s2,s2,616 # 80021530 <log>
    800042d0:	01892583          	lw	a1,24(s2)
    800042d4:	02892503          	lw	a0,40(s2)
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	fea080e7          	jalr	-22(ra) # 800032c2 <bread>
    800042e0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800042e2:	02c92683          	lw	a3,44(s2)
    800042e6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800042e8:	02d05763          	blez	a3,80004316 <write_head+0x5a>
    800042ec:	0001d797          	auipc	a5,0x1d
    800042f0:	27478793          	addi	a5,a5,628 # 80021560 <log+0x30>
    800042f4:	05c50713          	addi	a4,a0,92
    800042f8:	36fd                	addiw	a3,a3,-1
    800042fa:	1682                	slli	a3,a3,0x20
    800042fc:	9281                	srli	a3,a3,0x20
    800042fe:	068a                	slli	a3,a3,0x2
    80004300:	0001d617          	auipc	a2,0x1d
    80004304:	26460613          	addi	a2,a2,612 # 80021564 <log+0x34>
    80004308:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000430a:	4390                	lw	a2,0(a5)
    8000430c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000430e:	0791                	addi	a5,a5,4
    80004310:	0711                	addi	a4,a4,4
    80004312:	fed79ce3          	bne	a5,a3,8000430a <write_head+0x4e>
  }
  bwrite(buf);
    80004316:	8526                	mv	a0,s1
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	09c080e7          	jalr	156(ra) # 800033b4 <bwrite>
  brelse(buf);
    80004320:	8526                	mv	a0,s1
    80004322:	fffff097          	auipc	ra,0xfffff
    80004326:	0d0080e7          	jalr	208(ra) # 800033f2 <brelse>
}
    8000432a:	60e2                	ld	ra,24(sp)
    8000432c:	6442                	ld	s0,16(sp)
    8000432e:	64a2                	ld	s1,8(sp)
    80004330:	6902                	ld	s2,0(sp)
    80004332:	6105                	addi	sp,sp,32
    80004334:	8082                	ret

0000000080004336 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004336:	0001d797          	auipc	a5,0x1d
    8000433a:	2267a783          	lw	a5,550(a5) # 8002155c <log+0x2c>
    8000433e:	0af05d63          	blez	a5,800043f8 <install_trans+0xc2>
{
    80004342:	7139                	addi	sp,sp,-64
    80004344:	fc06                	sd	ra,56(sp)
    80004346:	f822                	sd	s0,48(sp)
    80004348:	f426                	sd	s1,40(sp)
    8000434a:	f04a                	sd	s2,32(sp)
    8000434c:	ec4e                	sd	s3,24(sp)
    8000434e:	e852                	sd	s4,16(sp)
    80004350:	e456                	sd	s5,8(sp)
    80004352:	e05a                	sd	s6,0(sp)
    80004354:	0080                	addi	s0,sp,64
    80004356:	8b2a                	mv	s6,a0
    80004358:	0001da97          	auipc	s5,0x1d
    8000435c:	208a8a93          	addi	s5,s5,520 # 80021560 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004360:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004362:	0001d997          	auipc	s3,0x1d
    80004366:	1ce98993          	addi	s3,s3,462 # 80021530 <log>
    8000436a:	a00d                	j	8000438c <install_trans+0x56>
    brelse(lbuf);
    8000436c:	854a                	mv	a0,s2
    8000436e:	fffff097          	auipc	ra,0xfffff
    80004372:	084080e7          	jalr	132(ra) # 800033f2 <brelse>
    brelse(dbuf);
    80004376:	8526                	mv	a0,s1
    80004378:	fffff097          	auipc	ra,0xfffff
    8000437c:	07a080e7          	jalr	122(ra) # 800033f2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004380:	2a05                	addiw	s4,s4,1
    80004382:	0a91                	addi	s5,s5,4
    80004384:	02c9a783          	lw	a5,44(s3)
    80004388:	04fa5e63          	bge	s4,a5,800043e4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000438c:	0189a583          	lw	a1,24(s3)
    80004390:	014585bb          	addw	a1,a1,s4
    80004394:	2585                	addiw	a1,a1,1
    80004396:	0289a503          	lw	a0,40(s3)
    8000439a:	fffff097          	auipc	ra,0xfffff
    8000439e:	f28080e7          	jalr	-216(ra) # 800032c2 <bread>
    800043a2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043a4:	000aa583          	lw	a1,0(s5)
    800043a8:	0289a503          	lw	a0,40(s3)
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	f16080e7          	jalr	-234(ra) # 800032c2 <bread>
    800043b4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043b6:	40000613          	li	a2,1024
    800043ba:	05890593          	addi	a1,s2,88
    800043be:	05850513          	addi	a0,a0,88
    800043c2:	ffffd097          	auipc	ra,0xffffd
    800043c6:	96c080e7          	jalr	-1684(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800043ca:	8526                	mv	a0,s1
    800043cc:	fffff097          	auipc	ra,0xfffff
    800043d0:	fe8080e7          	jalr	-24(ra) # 800033b4 <bwrite>
    if(recovering == 0)
    800043d4:	f80b1ce3          	bnez	s6,8000436c <install_trans+0x36>
      bunpin(dbuf);
    800043d8:	8526                	mv	a0,s1
    800043da:	fffff097          	auipc	ra,0xfffff
    800043de:	0f2080e7          	jalr	242(ra) # 800034cc <bunpin>
    800043e2:	b769                	j	8000436c <install_trans+0x36>
}
    800043e4:	70e2                	ld	ra,56(sp)
    800043e6:	7442                	ld	s0,48(sp)
    800043e8:	74a2                	ld	s1,40(sp)
    800043ea:	7902                	ld	s2,32(sp)
    800043ec:	69e2                	ld	s3,24(sp)
    800043ee:	6a42                	ld	s4,16(sp)
    800043f0:	6aa2                	ld	s5,8(sp)
    800043f2:	6b02                	ld	s6,0(sp)
    800043f4:	6121                	addi	sp,sp,64
    800043f6:	8082                	ret
    800043f8:	8082                	ret

00000000800043fa <initlog>:
{
    800043fa:	7179                	addi	sp,sp,-48
    800043fc:	f406                	sd	ra,40(sp)
    800043fe:	f022                	sd	s0,32(sp)
    80004400:	ec26                	sd	s1,24(sp)
    80004402:	e84a                	sd	s2,16(sp)
    80004404:	e44e                	sd	s3,8(sp)
    80004406:	1800                	addi	s0,sp,48
    80004408:	892a                	mv	s2,a0
    8000440a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000440c:	0001d497          	auipc	s1,0x1d
    80004410:	12448493          	addi	s1,s1,292 # 80021530 <log>
    80004414:	00004597          	auipc	a1,0x4
    80004418:	23c58593          	addi	a1,a1,572 # 80008650 <syscalls+0x1f0>
    8000441c:	8526                	mv	a0,s1
    8000441e:	ffffc097          	auipc	ra,0xffffc
    80004422:	728080e7          	jalr	1832(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004426:	0149a583          	lw	a1,20(s3)
    8000442a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000442c:	0109a783          	lw	a5,16(s3)
    80004430:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004432:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004436:	854a                	mv	a0,s2
    80004438:	fffff097          	auipc	ra,0xfffff
    8000443c:	e8a080e7          	jalr	-374(ra) # 800032c2 <bread>
  log.lh.n = lh->n;
    80004440:	4d34                	lw	a3,88(a0)
    80004442:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004444:	02d05563          	blez	a3,8000446e <initlog+0x74>
    80004448:	05c50793          	addi	a5,a0,92
    8000444c:	0001d717          	auipc	a4,0x1d
    80004450:	11470713          	addi	a4,a4,276 # 80021560 <log+0x30>
    80004454:	36fd                	addiw	a3,a3,-1
    80004456:	1682                	slli	a3,a3,0x20
    80004458:	9281                	srli	a3,a3,0x20
    8000445a:	068a                	slli	a3,a3,0x2
    8000445c:	06050613          	addi	a2,a0,96
    80004460:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004462:	4390                	lw	a2,0(a5)
    80004464:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004466:	0791                	addi	a5,a5,4
    80004468:	0711                	addi	a4,a4,4
    8000446a:	fed79ce3          	bne	a5,a3,80004462 <initlog+0x68>
  brelse(buf);
    8000446e:	fffff097          	auipc	ra,0xfffff
    80004472:	f84080e7          	jalr	-124(ra) # 800033f2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004476:	4505                	li	a0,1
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	ebe080e7          	jalr	-322(ra) # 80004336 <install_trans>
  log.lh.n = 0;
    80004480:	0001d797          	auipc	a5,0x1d
    80004484:	0c07ae23          	sw	zero,220(a5) # 8002155c <log+0x2c>
  write_head(); // clear the log
    80004488:	00000097          	auipc	ra,0x0
    8000448c:	e34080e7          	jalr	-460(ra) # 800042bc <write_head>
}
    80004490:	70a2                	ld	ra,40(sp)
    80004492:	7402                	ld	s0,32(sp)
    80004494:	64e2                	ld	s1,24(sp)
    80004496:	6942                	ld	s2,16(sp)
    80004498:	69a2                	ld	s3,8(sp)
    8000449a:	6145                	addi	sp,sp,48
    8000449c:	8082                	ret

000000008000449e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000449e:	1101                	addi	sp,sp,-32
    800044a0:	ec06                	sd	ra,24(sp)
    800044a2:	e822                	sd	s0,16(sp)
    800044a4:	e426                	sd	s1,8(sp)
    800044a6:	e04a                	sd	s2,0(sp)
    800044a8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044aa:	0001d517          	auipc	a0,0x1d
    800044ae:	08650513          	addi	a0,a0,134 # 80021530 <log>
    800044b2:	ffffc097          	auipc	ra,0xffffc
    800044b6:	724080e7          	jalr	1828(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800044ba:	0001d497          	auipc	s1,0x1d
    800044be:	07648493          	addi	s1,s1,118 # 80021530 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044c2:	4979                	li	s2,30
    800044c4:	a039                	j	800044d2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800044c6:	85a6                	mv	a1,s1
    800044c8:	8526                	mv	a0,s1
    800044ca:	ffffe097          	auipc	ra,0xffffe
    800044ce:	cb6080e7          	jalr	-842(ra) # 80002180 <sleep>
    if(log.committing){
    800044d2:	50dc                	lw	a5,36(s1)
    800044d4:	fbed                	bnez	a5,800044c6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044d6:	509c                	lw	a5,32(s1)
    800044d8:	0017871b          	addiw	a4,a5,1
    800044dc:	0007069b          	sext.w	a3,a4
    800044e0:	0027179b          	slliw	a5,a4,0x2
    800044e4:	9fb9                	addw	a5,a5,a4
    800044e6:	0017979b          	slliw	a5,a5,0x1
    800044ea:	54d8                	lw	a4,44(s1)
    800044ec:	9fb9                	addw	a5,a5,a4
    800044ee:	00f95963          	bge	s2,a5,80004500 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800044f2:	85a6                	mv	a1,s1
    800044f4:	8526                	mv	a0,s1
    800044f6:	ffffe097          	auipc	ra,0xffffe
    800044fa:	c8a080e7          	jalr	-886(ra) # 80002180 <sleep>
    800044fe:	bfd1                	j	800044d2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004500:	0001d517          	auipc	a0,0x1d
    80004504:	03050513          	addi	a0,a0,48 # 80021530 <log>
    80004508:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000450a:	ffffc097          	auipc	ra,0xffffc
    8000450e:	780080e7          	jalr	1920(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004512:	60e2                	ld	ra,24(sp)
    80004514:	6442                	ld	s0,16(sp)
    80004516:	64a2                	ld	s1,8(sp)
    80004518:	6902                	ld	s2,0(sp)
    8000451a:	6105                	addi	sp,sp,32
    8000451c:	8082                	ret

000000008000451e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000451e:	7139                	addi	sp,sp,-64
    80004520:	fc06                	sd	ra,56(sp)
    80004522:	f822                	sd	s0,48(sp)
    80004524:	f426                	sd	s1,40(sp)
    80004526:	f04a                	sd	s2,32(sp)
    80004528:	ec4e                	sd	s3,24(sp)
    8000452a:	e852                	sd	s4,16(sp)
    8000452c:	e456                	sd	s5,8(sp)
    8000452e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004530:	0001d497          	auipc	s1,0x1d
    80004534:	00048493          	mv	s1,s1
    80004538:	8526                	mv	a0,s1
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	69c080e7          	jalr	1692(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004542:	509c                	lw	a5,32(s1)
    80004544:	37fd                	addiw	a5,a5,-1
    80004546:	0007891b          	sext.w	s2,a5
    8000454a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000454c:	50dc                	lw	a5,36(s1)
    8000454e:	e7b9                	bnez	a5,8000459c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004550:	04091e63          	bnez	s2,800045ac <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004554:	0001d497          	auipc	s1,0x1d
    80004558:	fdc48493          	addi	s1,s1,-36 # 80021530 <log>
    8000455c:	4785                	li	a5,1
    8000455e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004560:	8526                	mv	a0,s1
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	728080e7          	jalr	1832(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000456a:	54dc                	lw	a5,44(s1)
    8000456c:	06f04763          	bgtz	a5,800045da <end_op+0xbc>
    acquire(&log.lock);
    80004570:	0001d497          	auipc	s1,0x1d
    80004574:	fc048493          	addi	s1,s1,-64 # 80021530 <log>
    80004578:	8526                	mv	a0,s1
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	65c080e7          	jalr	1628(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004582:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004586:	8526                	mv	a0,s1
    80004588:	ffffe097          	auipc	ra,0xffffe
    8000458c:	c5c080e7          	jalr	-932(ra) # 800021e4 <wakeup>
    release(&log.lock);
    80004590:	8526                	mv	a0,s1
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	6f8080e7          	jalr	1784(ra) # 80000c8a <release>
}
    8000459a:	a03d                	j	800045c8 <end_op+0xaa>
    panic("log.committing");
    8000459c:	00004517          	auipc	a0,0x4
    800045a0:	0bc50513          	addi	a0,a0,188 # 80008658 <syscalls+0x1f8>
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	f9a080e7          	jalr	-102(ra) # 8000053e <panic>
    wakeup(&log);
    800045ac:	0001d497          	auipc	s1,0x1d
    800045b0:	f8448493          	addi	s1,s1,-124 # 80021530 <log>
    800045b4:	8526                	mv	a0,s1
    800045b6:	ffffe097          	auipc	ra,0xffffe
    800045ba:	c2e080e7          	jalr	-978(ra) # 800021e4 <wakeup>
  release(&log.lock);
    800045be:	8526                	mv	a0,s1
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	6ca080e7          	jalr	1738(ra) # 80000c8a <release>
}
    800045c8:	70e2                	ld	ra,56(sp)
    800045ca:	7442                	ld	s0,48(sp)
    800045cc:	74a2                	ld	s1,40(sp)
    800045ce:	7902                	ld	s2,32(sp)
    800045d0:	69e2                	ld	s3,24(sp)
    800045d2:	6a42                	ld	s4,16(sp)
    800045d4:	6aa2                	ld	s5,8(sp)
    800045d6:	6121                	addi	sp,sp,64
    800045d8:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800045da:	0001da97          	auipc	s5,0x1d
    800045de:	f86a8a93          	addi	s5,s5,-122 # 80021560 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800045e2:	0001da17          	auipc	s4,0x1d
    800045e6:	f4ea0a13          	addi	s4,s4,-178 # 80021530 <log>
    800045ea:	018a2583          	lw	a1,24(s4)
    800045ee:	012585bb          	addw	a1,a1,s2
    800045f2:	2585                	addiw	a1,a1,1
    800045f4:	028a2503          	lw	a0,40(s4)
    800045f8:	fffff097          	auipc	ra,0xfffff
    800045fc:	cca080e7          	jalr	-822(ra) # 800032c2 <bread>
    80004600:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004602:	000aa583          	lw	a1,0(s5)
    80004606:	028a2503          	lw	a0,40(s4)
    8000460a:	fffff097          	auipc	ra,0xfffff
    8000460e:	cb8080e7          	jalr	-840(ra) # 800032c2 <bread>
    80004612:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004614:	40000613          	li	a2,1024
    80004618:	05850593          	addi	a1,a0,88
    8000461c:	05848513          	addi	a0,s1,88
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	70e080e7          	jalr	1806(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004628:	8526                	mv	a0,s1
    8000462a:	fffff097          	auipc	ra,0xfffff
    8000462e:	d8a080e7          	jalr	-630(ra) # 800033b4 <bwrite>
    brelse(from);
    80004632:	854e                	mv	a0,s3
    80004634:	fffff097          	auipc	ra,0xfffff
    80004638:	dbe080e7          	jalr	-578(ra) # 800033f2 <brelse>
    brelse(to);
    8000463c:	8526                	mv	a0,s1
    8000463e:	fffff097          	auipc	ra,0xfffff
    80004642:	db4080e7          	jalr	-588(ra) # 800033f2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004646:	2905                	addiw	s2,s2,1
    80004648:	0a91                	addi	s5,s5,4
    8000464a:	02ca2783          	lw	a5,44(s4)
    8000464e:	f8f94ee3          	blt	s2,a5,800045ea <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004652:	00000097          	auipc	ra,0x0
    80004656:	c6a080e7          	jalr	-918(ra) # 800042bc <write_head>
    install_trans(0); // Now install writes to home locations
    8000465a:	4501                	li	a0,0
    8000465c:	00000097          	auipc	ra,0x0
    80004660:	cda080e7          	jalr	-806(ra) # 80004336 <install_trans>
    log.lh.n = 0;
    80004664:	0001d797          	auipc	a5,0x1d
    80004668:	ee07ac23          	sw	zero,-264(a5) # 8002155c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000466c:	00000097          	auipc	ra,0x0
    80004670:	c50080e7          	jalr	-944(ra) # 800042bc <write_head>
    80004674:	bdf5                	j	80004570 <end_op+0x52>

0000000080004676 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004676:	1101                	addi	sp,sp,-32
    80004678:	ec06                	sd	ra,24(sp)
    8000467a:	e822                	sd	s0,16(sp)
    8000467c:	e426                	sd	s1,8(sp)
    8000467e:	e04a                	sd	s2,0(sp)
    80004680:	1000                	addi	s0,sp,32
    80004682:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004684:	0001d917          	auipc	s2,0x1d
    80004688:	eac90913          	addi	s2,s2,-340 # 80021530 <log>
    8000468c:	854a                	mv	a0,s2
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	548080e7          	jalr	1352(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004696:	02c92603          	lw	a2,44(s2)
    8000469a:	47f5                	li	a5,29
    8000469c:	06c7c563          	blt	a5,a2,80004706 <log_write+0x90>
    800046a0:	0001d797          	auipc	a5,0x1d
    800046a4:	eac7a783          	lw	a5,-340(a5) # 8002154c <log+0x1c>
    800046a8:	37fd                	addiw	a5,a5,-1
    800046aa:	04f65e63          	bge	a2,a5,80004706 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046ae:	0001d797          	auipc	a5,0x1d
    800046b2:	ea27a783          	lw	a5,-350(a5) # 80021550 <log+0x20>
    800046b6:	06f05063          	blez	a5,80004716 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046ba:	4781                	li	a5,0
    800046bc:	06c05563          	blez	a2,80004726 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046c0:	44cc                	lw	a1,12(s1)
    800046c2:	0001d717          	auipc	a4,0x1d
    800046c6:	e9e70713          	addi	a4,a4,-354 # 80021560 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046ca:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046cc:	4314                	lw	a3,0(a4)
    800046ce:	04b68c63          	beq	a3,a1,80004726 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046d2:	2785                	addiw	a5,a5,1
    800046d4:	0711                	addi	a4,a4,4
    800046d6:	fef61be3          	bne	a2,a5,800046cc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800046da:	0621                	addi	a2,a2,8
    800046dc:	060a                	slli	a2,a2,0x2
    800046de:	0001d797          	auipc	a5,0x1d
    800046e2:	e5278793          	addi	a5,a5,-430 # 80021530 <log>
    800046e6:	963e                	add	a2,a2,a5
    800046e8:	44dc                	lw	a5,12(s1)
    800046ea:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800046ec:	8526                	mv	a0,s1
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	da2080e7          	jalr	-606(ra) # 80003490 <bpin>
    log.lh.n++;
    800046f6:	0001d717          	auipc	a4,0x1d
    800046fa:	e3a70713          	addi	a4,a4,-454 # 80021530 <log>
    800046fe:	575c                	lw	a5,44(a4)
    80004700:	2785                	addiw	a5,a5,1
    80004702:	d75c                	sw	a5,44(a4)
    80004704:	a835                	j	80004740 <log_write+0xca>
    panic("too big a transaction");
    80004706:	00004517          	auipc	a0,0x4
    8000470a:	f6250513          	addi	a0,a0,-158 # 80008668 <syscalls+0x208>
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	e30080e7          	jalr	-464(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004716:	00004517          	auipc	a0,0x4
    8000471a:	f6a50513          	addi	a0,a0,-150 # 80008680 <syscalls+0x220>
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	e20080e7          	jalr	-480(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004726:	00878713          	addi	a4,a5,8
    8000472a:	00271693          	slli	a3,a4,0x2
    8000472e:	0001d717          	auipc	a4,0x1d
    80004732:	e0270713          	addi	a4,a4,-510 # 80021530 <log>
    80004736:	9736                	add	a4,a4,a3
    80004738:	44d4                	lw	a3,12(s1)
    8000473a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000473c:	faf608e3          	beq	a2,a5,800046ec <log_write+0x76>
  }
  release(&log.lock);
    80004740:	0001d517          	auipc	a0,0x1d
    80004744:	df050513          	addi	a0,a0,-528 # 80021530 <log>
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	542080e7          	jalr	1346(ra) # 80000c8a <release>
}
    80004750:	60e2                	ld	ra,24(sp)
    80004752:	6442                	ld	s0,16(sp)
    80004754:	64a2                	ld	s1,8(sp)
    80004756:	6902                	ld	s2,0(sp)
    80004758:	6105                	addi	sp,sp,32
    8000475a:	8082                	ret

000000008000475c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000475c:	1101                	addi	sp,sp,-32
    8000475e:	ec06                	sd	ra,24(sp)
    80004760:	e822                	sd	s0,16(sp)
    80004762:	e426                	sd	s1,8(sp)
    80004764:	e04a                	sd	s2,0(sp)
    80004766:	1000                	addi	s0,sp,32
    80004768:	84aa                	mv	s1,a0
    8000476a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000476c:	00004597          	auipc	a1,0x4
    80004770:	f3458593          	addi	a1,a1,-204 # 800086a0 <syscalls+0x240>
    80004774:	0521                	addi	a0,a0,8
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	3d0080e7          	jalr	976(ra) # 80000b46 <initlock>
  lk->name = name;
    8000477e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004782:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004786:	0204a423          	sw	zero,40(s1)
}
    8000478a:	60e2                	ld	ra,24(sp)
    8000478c:	6442                	ld	s0,16(sp)
    8000478e:	64a2                	ld	s1,8(sp)
    80004790:	6902                	ld	s2,0(sp)
    80004792:	6105                	addi	sp,sp,32
    80004794:	8082                	ret

0000000080004796 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004796:	1101                	addi	sp,sp,-32
    80004798:	ec06                	sd	ra,24(sp)
    8000479a:	e822                	sd	s0,16(sp)
    8000479c:	e426                	sd	s1,8(sp)
    8000479e:	e04a                	sd	s2,0(sp)
    800047a0:	1000                	addi	s0,sp,32
    800047a2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047a4:	00850913          	addi	s2,a0,8
    800047a8:	854a                	mv	a0,s2
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	42c080e7          	jalr	1068(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800047b2:	409c                	lw	a5,0(s1)
    800047b4:	cb89                	beqz	a5,800047c6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047b6:	85ca                	mv	a1,s2
    800047b8:	8526                	mv	a0,s1
    800047ba:	ffffe097          	auipc	ra,0xffffe
    800047be:	9c6080e7          	jalr	-1594(ra) # 80002180 <sleep>
  while (lk->locked) {
    800047c2:	409c                	lw	a5,0(s1)
    800047c4:	fbed                	bnez	a5,800047b6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047c6:	4785                	li	a5,1
    800047c8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047ca:	ffffd097          	auipc	ra,0xffffd
    800047ce:	1e2080e7          	jalr	482(ra) # 800019ac <myproc>
    800047d2:	591c                	lw	a5,48(a0)
    800047d4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047d6:	854a                	mv	a0,s2
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	4b2080e7          	jalr	1202(ra) # 80000c8a <release>
}
    800047e0:	60e2                	ld	ra,24(sp)
    800047e2:	6442                	ld	s0,16(sp)
    800047e4:	64a2                	ld	s1,8(sp)
    800047e6:	6902                	ld	s2,0(sp)
    800047e8:	6105                	addi	sp,sp,32
    800047ea:	8082                	ret

00000000800047ec <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800047ec:	1101                	addi	sp,sp,-32
    800047ee:	ec06                	sd	ra,24(sp)
    800047f0:	e822                	sd	s0,16(sp)
    800047f2:	e426                	sd	s1,8(sp)
    800047f4:	e04a                	sd	s2,0(sp)
    800047f6:	1000                	addi	s0,sp,32
    800047f8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047fa:	00850913          	addi	s2,a0,8
    800047fe:	854a                	mv	a0,s2
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	3d6080e7          	jalr	982(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004808:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000480c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004810:	8526                	mv	a0,s1
    80004812:	ffffe097          	auipc	ra,0xffffe
    80004816:	9d2080e7          	jalr	-1582(ra) # 800021e4 <wakeup>
  release(&lk->lk);
    8000481a:	854a                	mv	a0,s2
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	46e080e7          	jalr	1134(ra) # 80000c8a <release>
}
    80004824:	60e2                	ld	ra,24(sp)
    80004826:	6442                	ld	s0,16(sp)
    80004828:	64a2                	ld	s1,8(sp)
    8000482a:	6902                	ld	s2,0(sp)
    8000482c:	6105                	addi	sp,sp,32
    8000482e:	8082                	ret

0000000080004830 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004830:	7179                	addi	sp,sp,-48
    80004832:	f406                	sd	ra,40(sp)
    80004834:	f022                	sd	s0,32(sp)
    80004836:	ec26                	sd	s1,24(sp)
    80004838:	e84a                	sd	s2,16(sp)
    8000483a:	e44e                	sd	s3,8(sp)
    8000483c:	1800                	addi	s0,sp,48
    8000483e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004840:	00850913          	addi	s2,a0,8
    80004844:	854a                	mv	a0,s2
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	390080e7          	jalr	912(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000484e:	409c                	lw	a5,0(s1)
    80004850:	ef99                	bnez	a5,8000486e <holdingsleep+0x3e>
    80004852:	4481                	li	s1,0
  release(&lk->lk);
    80004854:	854a                	mv	a0,s2
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	434080e7          	jalr	1076(ra) # 80000c8a <release>
  return r;
}
    8000485e:	8526                	mv	a0,s1
    80004860:	70a2                	ld	ra,40(sp)
    80004862:	7402                	ld	s0,32(sp)
    80004864:	64e2                	ld	s1,24(sp)
    80004866:	6942                	ld	s2,16(sp)
    80004868:	69a2                	ld	s3,8(sp)
    8000486a:	6145                	addi	sp,sp,48
    8000486c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000486e:	0284a983          	lw	s3,40(s1)
    80004872:	ffffd097          	auipc	ra,0xffffd
    80004876:	13a080e7          	jalr	314(ra) # 800019ac <myproc>
    8000487a:	5904                	lw	s1,48(a0)
    8000487c:	413484b3          	sub	s1,s1,s3
    80004880:	0014b493          	seqz	s1,s1
    80004884:	bfc1                	j	80004854 <holdingsleep+0x24>

0000000080004886 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004886:	1141                	addi	sp,sp,-16
    80004888:	e406                	sd	ra,8(sp)
    8000488a:	e022                	sd	s0,0(sp)
    8000488c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000488e:	00004597          	auipc	a1,0x4
    80004892:	e2258593          	addi	a1,a1,-478 # 800086b0 <syscalls+0x250>
    80004896:	0001d517          	auipc	a0,0x1d
    8000489a:	de250513          	addi	a0,a0,-542 # 80021678 <ftable>
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	2a8080e7          	jalr	680(ra) # 80000b46 <initlock>
}
    800048a6:	60a2                	ld	ra,8(sp)
    800048a8:	6402                	ld	s0,0(sp)
    800048aa:	0141                	addi	sp,sp,16
    800048ac:	8082                	ret

00000000800048ae <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048ae:	1101                	addi	sp,sp,-32
    800048b0:	ec06                	sd	ra,24(sp)
    800048b2:	e822                	sd	s0,16(sp)
    800048b4:	e426                	sd	s1,8(sp)
    800048b6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048b8:	0001d517          	auipc	a0,0x1d
    800048bc:	dc050513          	addi	a0,a0,-576 # 80021678 <ftable>
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	316080e7          	jalr	790(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048c8:	0001d497          	auipc	s1,0x1d
    800048cc:	dc848493          	addi	s1,s1,-568 # 80021690 <ftable+0x18>
    800048d0:	0001e717          	auipc	a4,0x1e
    800048d4:	d6070713          	addi	a4,a4,-672 # 80022630 <disk>
    if(f->ref == 0){
    800048d8:	40dc                	lw	a5,4(s1)
    800048da:	cf99                	beqz	a5,800048f8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048dc:	02848493          	addi	s1,s1,40
    800048e0:	fee49ce3          	bne	s1,a4,800048d8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800048e4:	0001d517          	auipc	a0,0x1d
    800048e8:	d9450513          	addi	a0,a0,-620 # 80021678 <ftable>
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	39e080e7          	jalr	926(ra) # 80000c8a <release>
  return 0;
    800048f4:	4481                	li	s1,0
    800048f6:	a819                	j	8000490c <filealloc+0x5e>
      f->ref = 1;
    800048f8:	4785                	li	a5,1
    800048fa:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800048fc:	0001d517          	auipc	a0,0x1d
    80004900:	d7c50513          	addi	a0,a0,-644 # 80021678 <ftable>
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	386080e7          	jalr	902(ra) # 80000c8a <release>
}
    8000490c:	8526                	mv	a0,s1
    8000490e:	60e2                	ld	ra,24(sp)
    80004910:	6442                	ld	s0,16(sp)
    80004912:	64a2                	ld	s1,8(sp)
    80004914:	6105                	addi	sp,sp,32
    80004916:	8082                	ret

0000000080004918 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004918:	1101                	addi	sp,sp,-32
    8000491a:	ec06                	sd	ra,24(sp)
    8000491c:	e822                	sd	s0,16(sp)
    8000491e:	e426                	sd	s1,8(sp)
    80004920:	1000                	addi	s0,sp,32
    80004922:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004924:	0001d517          	auipc	a0,0x1d
    80004928:	d5450513          	addi	a0,a0,-684 # 80021678 <ftable>
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	2aa080e7          	jalr	682(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004934:	40dc                	lw	a5,4(s1)
    80004936:	02f05263          	blez	a5,8000495a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000493a:	2785                	addiw	a5,a5,1
    8000493c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000493e:	0001d517          	auipc	a0,0x1d
    80004942:	d3a50513          	addi	a0,a0,-710 # 80021678 <ftable>
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	344080e7          	jalr	836(ra) # 80000c8a <release>
  return f;
}
    8000494e:	8526                	mv	a0,s1
    80004950:	60e2                	ld	ra,24(sp)
    80004952:	6442                	ld	s0,16(sp)
    80004954:	64a2                	ld	s1,8(sp)
    80004956:	6105                	addi	sp,sp,32
    80004958:	8082                	ret
    panic("filedup");
    8000495a:	00004517          	auipc	a0,0x4
    8000495e:	d5e50513          	addi	a0,a0,-674 # 800086b8 <syscalls+0x258>
    80004962:	ffffc097          	auipc	ra,0xffffc
    80004966:	bdc080e7          	jalr	-1060(ra) # 8000053e <panic>

000000008000496a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000496a:	7139                	addi	sp,sp,-64
    8000496c:	fc06                	sd	ra,56(sp)
    8000496e:	f822                	sd	s0,48(sp)
    80004970:	f426                	sd	s1,40(sp)
    80004972:	f04a                	sd	s2,32(sp)
    80004974:	ec4e                	sd	s3,24(sp)
    80004976:	e852                	sd	s4,16(sp)
    80004978:	e456                	sd	s5,8(sp)
    8000497a:	0080                	addi	s0,sp,64
    8000497c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000497e:	0001d517          	auipc	a0,0x1d
    80004982:	cfa50513          	addi	a0,a0,-774 # 80021678 <ftable>
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	250080e7          	jalr	592(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000498e:	40dc                	lw	a5,4(s1)
    80004990:	06f05163          	blez	a5,800049f2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004994:	37fd                	addiw	a5,a5,-1
    80004996:	0007871b          	sext.w	a4,a5
    8000499a:	c0dc                	sw	a5,4(s1)
    8000499c:	06e04363          	bgtz	a4,80004a02 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049a0:	0004a903          	lw	s2,0(s1)
    800049a4:	0094ca83          	lbu	s5,9(s1)
    800049a8:	0104ba03          	ld	s4,16(s1)
    800049ac:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049b0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049b4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049b8:	0001d517          	auipc	a0,0x1d
    800049bc:	cc050513          	addi	a0,a0,-832 # 80021678 <ftable>
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	2ca080e7          	jalr	714(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800049c8:	4785                	li	a5,1
    800049ca:	04f90d63          	beq	s2,a5,80004a24 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049ce:	3979                	addiw	s2,s2,-2
    800049d0:	4785                	li	a5,1
    800049d2:	0527e063          	bltu	a5,s2,80004a12 <fileclose+0xa8>
    begin_op();
    800049d6:	00000097          	auipc	ra,0x0
    800049da:	ac8080e7          	jalr	-1336(ra) # 8000449e <begin_op>
    iput(ff.ip);
    800049de:	854e                	mv	a0,s3
    800049e0:	fffff097          	auipc	ra,0xfffff
    800049e4:	2b6080e7          	jalr	694(ra) # 80003c96 <iput>
    end_op();
    800049e8:	00000097          	auipc	ra,0x0
    800049ec:	b36080e7          	jalr	-1226(ra) # 8000451e <end_op>
    800049f0:	a00d                	j	80004a12 <fileclose+0xa8>
    panic("fileclose");
    800049f2:	00004517          	auipc	a0,0x4
    800049f6:	cce50513          	addi	a0,a0,-818 # 800086c0 <syscalls+0x260>
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	b44080e7          	jalr	-1212(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004a02:	0001d517          	auipc	a0,0x1d
    80004a06:	c7650513          	addi	a0,a0,-906 # 80021678 <ftable>
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	280080e7          	jalr	640(ra) # 80000c8a <release>
  }
}
    80004a12:	70e2                	ld	ra,56(sp)
    80004a14:	7442                	ld	s0,48(sp)
    80004a16:	74a2                	ld	s1,40(sp)
    80004a18:	7902                	ld	s2,32(sp)
    80004a1a:	69e2                	ld	s3,24(sp)
    80004a1c:	6a42                	ld	s4,16(sp)
    80004a1e:	6aa2                	ld	s5,8(sp)
    80004a20:	6121                	addi	sp,sp,64
    80004a22:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a24:	85d6                	mv	a1,s5
    80004a26:	8552                	mv	a0,s4
    80004a28:	00000097          	auipc	ra,0x0
    80004a2c:	34c080e7          	jalr	844(ra) # 80004d74 <pipeclose>
    80004a30:	b7cd                	j	80004a12 <fileclose+0xa8>

0000000080004a32 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a32:	715d                	addi	sp,sp,-80
    80004a34:	e486                	sd	ra,72(sp)
    80004a36:	e0a2                	sd	s0,64(sp)
    80004a38:	fc26                	sd	s1,56(sp)
    80004a3a:	f84a                	sd	s2,48(sp)
    80004a3c:	f44e                	sd	s3,40(sp)
    80004a3e:	0880                	addi	s0,sp,80
    80004a40:	84aa                	mv	s1,a0
    80004a42:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a44:	ffffd097          	auipc	ra,0xffffd
    80004a48:	f68080e7          	jalr	-152(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a4c:	409c                	lw	a5,0(s1)
    80004a4e:	37f9                	addiw	a5,a5,-2
    80004a50:	4705                	li	a4,1
    80004a52:	04f76763          	bltu	a4,a5,80004aa0 <filestat+0x6e>
    80004a56:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a58:	6c88                	ld	a0,24(s1)
    80004a5a:	fffff097          	auipc	ra,0xfffff
    80004a5e:	082080e7          	jalr	130(ra) # 80003adc <ilock>
    stati(f->ip, &st);
    80004a62:	fb840593          	addi	a1,s0,-72
    80004a66:	6c88                	ld	a0,24(s1)
    80004a68:	fffff097          	auipc	ra,0xfffff
    80004a6c:	2fe080e7          	jalr	766(ra) # 80003d66 <stati>
    iunlock(f->ip);
    80004a70:	6c88                	ld	a0,24(s1)
    80004a72:	fffff097          	auipc	ra,0xfffff
    80004a76:	12c080e7          	jalr	300(ra) # 80003b9e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a7a:	46e1                	li	a3,24
    80004a7c:	fb840613          	addi	a2,s0,-72
    80004a80:	85ce                	mv	a1,s3
    80004a82:	05093503          	ld	a0,80(s2)
    80004a86:	ffffd097          	auipc	ra,0xffffd
    80004a8a:	be2080e7          	jalr	-1054(ra) # 80001668 <copyout>
    80004a8e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a92:	60a6                	ld	ra,72(sp)
    80004a94:	6406                	ld	s0,64(sp)
    80004a96:	74e2                	ld	s1,56(sp)
    80004a98:	7942                	ld	s2,48(sp)
    80004a9a:	79a2                	ld	s3,40(sp)
    80004a9c:	6161                	addi	sp,sp,80
    80004a9e:	8082                	ret
  return -1;
    80004aa0:	557d                	li	a0,-1
    80004aa2:	bfc5                	j	80004a92 <filestat+0x60>

0000000080004aa4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004aa4:	7179                	addi	sp,sp,-48
    80004aa6:	f406                	sd	ra,40(sp)
    80004aa8:	f022                	sd	s0,32(sp)
    80004aaa:	ec26                	sd	s1,24(sp)
    80004aac:	e84a                	sd	s2,16(sp)
    80004aae:	e44e                	sd	s3,8(sp)
    80004ab0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ab2:	00854783          	lbu	a5,8(a0)
    80004ab6:	c3d5                	beqz	a5,80004b5a <fileread+0xb6>
    80004ab8:	84aa                	mv	s1,a0
    80004aba:	89ae                	mv	s3,a1
    80004abc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004abe:	411c                	lw	a5,0(a0)
    80004ac0:	4705                	li	a4,1
    80004ac2:	04e78963          	beq	a5,a4,80004b14 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ac6:	470d                	li	a4,3
    80004ac8:	04e78d63          	beq	a5,a4,80004b22 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004acc:	4709                	li	a4,2
    80004ace:	06e79e63          	bne	a5,a4,80004b4a <fileread+0xa6>
    ilock(f->ip);
    80004ad2:	6d08                	ld	a0,24(a0)
    80004ad4:	fffff097          	auipc	ra,0xfffff
    80004ad8:	008080e7          	jalr	8(ra) # 80003adc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004adc:	874a                	mv	a4,s2
    80004ade:	5094                	lw	a3,32(s1)
    80004ae0:	864e                	mv	a2,s3
    80004ae2:	4585                	li	a1,1
    80004ae4:	6c88                	ld	a0,24(s1)
    80004ae6:	fffff097          	auipc	ra,0xfffff
    80004aea:	2aa080e7          	jalr	682(ra) # 80003d90 <readi>
    80004aee:	892a                	mv	s2,a0
    80004af0:	00a05563          	blez	a0,80004afa <fileread+0x56>
      f->off += r;
    80004af4:	509c                	lw	a5,32(s1)
    80004af6:	9fa9                	addw	a5,a5,a0
    80004af8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004afa:	6c88                	ld	a0,24(s1)
    80004afc:	fffff097          	auipc	ra,0xfffff
    80004b00:	0a2080e7          	jalr	162(ra) # 80003b9e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b04:	854a                	mv	a0,s2
    80004b06:	70a2                	ld	ra,40(sp)
    80004b08:	7402                	ld	s0,32(sp)
    80004b0a:	64e2                	ld	s1,24(sp)
    80004b0c:	6942                	ld	s2,16(sp)
    80004b0e:	69a2                	ld	s3,8(sp)
    80004b10:	6145                	addi	sp,sp,48
    80004b12:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b14:	6908                	ld	a0,16(a0)
    80004b16:	00000097          	auipc	ra,0x0
    80004b1a:	3c6080e7          	jalr	966(ra) # 80004edc <piperead>
    80004b1e:	892a                	mv	s2,a0
    80004b20:	b7d5                	j	80004b04 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b22:	02451783          	lh	a5,36(a0)
    80004b26:	03079693          	slli	a3,a5,0x30
    80004b2a:	92c1                	srli	a3,a3,0x30
    80004b2c:	4725                	li	a4,9
    80004b2e:	02d76863          	bltu	a4,a3,80004b5e <fileread+0xba>
    80004b32:	0792                	slli	a5,a5,0x4
    80004b34:	0001d717          	auipc	a4,0x1d
    80004b38:	aa470713          	addi	a4,a4,-1372 # 800215d8 <devsw>
    80004b3c:	97ba                	add	a5,a5,a4
    80004b3e:	639c                	ld	a5,0(a5)
    80004b40:	c38d                	beqz	a5,80004b62 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b42:	4505                	li	a0,1
    80004b44:	9782                	jalr	a5
    80004b46:	892a                	mv	s2,a0
    80004b48:	bf75                	j	80004b04 <fileread+0x60>
    panic("fileread");
    80004b4a:	00004517          	auipc	a0,0x4
    80004b4e:	b8650513          	addi	a0,a0,-1146 # 800086d0 <syscalls+0x270>
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	9ec080e7          	jalr	-1556(ra) # 8000053e <panic>
    return -1;
    80004b5a:	597d                	li	s2,-1
    80004b5c:	b765                	j	80004b04 <fileread+0x60>
      return -1;
    80004b5e:	597d                	li	s2,-1
    80004b60:	b755                	j	80004b04 <fileread+0x60>
    80004b62:	597d                	li	s2,-1
    80004b64:	b745                	j	80004b04 <fileread+0x60>

0000000080004b66 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b66:	715d                	addi	sp,sp,-80
    80004b68:	e486                	sd	ra,72(sp)
    80004b6a:	e0a2                	sd	s0,64(sp)
    80004b6c:	fc26                	sd	s1,56(sp)
    80004b6e:	f84a                	sd	s2,48(sp)
    80004b70:	f44e                	sd	s3,40(sp)
    80004b72:	f052                	sd	s4,32(sp)
    80004b74:	ec56                	sd	s5,24(sp)
    80004b76:	e85a                	sd	s6,16(sp)
    80004b78:	e45e                	sd	s7,8(sp)
    80004b7a:	e062                	sd	s8,0(sp)
    80004b7c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b7e:	00954783          	lbu	a5,9(a0)
    80004b82:	10078663          	beqz	a5,80004c8e <filewrite+0x128>
    80004b86:	892a                	mv	s2,a0
    80004b88:	8aae                	mv	s5,a1
    80004b8a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b8c:	411c                	lw	a5,0(a0)
    80004b8e:	4705                	li	a4,1
    80004b90:	02e78263          	beq	a5,a4,80004bb4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b94:	470d                	li	a4,3
    80004b96:	02e78663          	beq	a5,a4,80004bc2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b9a:	4709                	li	a4,2
    80004b9c:	0ee79163          	bne	a5,a4,80004c7e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ba0:	0ac05d63          	blez	a2,80004c5a <filewrite+0xf4>
    int i = 0;
    80004ba4:	4981                	li	s3,0
    80004ba6:	6b05                	lui	s6,0x1
    80004ba8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004bac:	6b85                	lui	s7,0x1
    80004bae:	c00b8b9b          	addiw	s7,s7,-1024
    80004bb2:	a861                	j	80004c4a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004bb4:	6908                	ld	a0,16(a0)
    80004bb6:	00000097          	auipc	ra,0x0
    80004bba:	22e080e7          	jalr	558(ra) # 80004de4 <pipewrite>
    80004bbe:	8a2a                	mv	s4,a0
    80004bc0:	a045                	j	80004c60 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004bc2:	02451783          	lh	a5,36(a0)
    80004bc6:	03079693          	slli	a3,a5,0x30
    80004bca:	92c1                	srli	a3,a3,0x30
    80004bcc:	4725                	li	a4,9
    80004bce:	0cd76263          	bltu	a4,a3,80004c92 <filewrite+0x12c>
    80004bd2:	0792                	slli	a5,a5,0x4
    80004bd4:	0001d717          	auipc	a4,0x1d
    80004bd8:	a0470713          	addi	a4,a4,-1532 # 800215d8 <devsw>
    80004bdc:	97ba                	add	a5,a5,a4
    80004bde:	679c                	ld	a5,8(a5)
    80004be0:	cbdd                	beqz	a5,80004c96 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004be2:	4505                	li	a0,1
    80004be4:	9782                	jalr	a5
    80004be6:	8a2a                	mv	s4,a0
    80004be8:	a8a5                	j	80004c60 <filewrite+0xfa>
    80004bea:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004bee:	00000097          	auipc	ra,0x0
    80004bf2:	8b0080e7          	jalr	-1872(ra) # 8000449e <begin_op>
      ilock(f->ip);
    80004bf6:	01893503          	ld	a0,24(s2)
    80004bfa:	fffff097          	auipc	ra,0xfffff
    80004bfe:	ee2080e7          	jalr	-286(ra) # 80003adc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c02:	8762                	mv	a4,s8
    80004c04:	02092683          	lw	a3,32(s2)
    80004c08:	01598633          	add	a2,s3,s5
    80004c0c:	4585                	li	a1,1
    80004c0e:	01893503          	ld	a0,24(s2)
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	276080e7          	jalr	630(ra) # 80003e88 <writei>
    80004c1a:	84aa                	mv	s1,a0
    80004c1c:	00a05763          	blez	a0,80004c2a <filewrite+0xc4>
        f->off += r;
    80004c20:	02092783          	lw	a5,32(s2)
    80004c24:	9fa9                	addw	a5,a5,a0
    80004c26:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c2a:	01893503          	ld	a0,24(s2)
    80004c2e:	fffff097          	auipc	ra,0xfffff
    80004c32:	f70080e7          	jalr	-144(ra) # 80003b9e <iunlock>
      end_op();
    80004c36:	00000097          	auipc	ra,0x0
    80004c3a:	8e8080e7          	jalr	-1816(ra) # 8000451e <end_op>

      if(r != n1){
    80004c3e:	009c1f63          	bne	s8,s1,80004c5c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c42:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c46:	0149db63          	bge	s3,s4,80004c5c <filewrite+0xf6>
      int n1 = n - i;
    80004c4a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c4e:	84be                	mv	s1,a5
    80004c50:	2781                	sext.w	a5,a5
    80004c52:	f8fb5ce3          	bge	s6,a5,80004bea <filewrite+0x84>
    80004c56:	84de                	mv	s1,s7
    80004c58:	bf49                	j	80004bea <filewrite+0x84>
    int i = 0;
    80004c5a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c5c:	013a1f63          	bne	s4,s3,80004c7a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c60:	8552                	mv	a0,s4
    80004c62:	60a6                	ld	ra,72(sp)
    80004c64:	6406                	ld	s0,64(sp)
    80004c66:	74e2                	ld	s1,56(sp)
    80004c68:	7942                	ld	s2,48(sp)
    80004c6a:	79a2                	ld	s3,40(sp)
    80004c6c:	7a02                	ld	s4,32(sp)
    80004c6e:	6ae2                	ld	s5,24(sp)
    80004c70:	6b42                	ld	s6,16(sp)
    80004c72:	6ba2                	ld	s7,8(sp)
    80004c74:	6c02                	ld	s8,0(sp)
    80004c76:	6161                	addi	sp,sp,80
    80004c78:	8082                	ret
    ret = (i == n ? n : -1);
    80004c7a:	5a7d                	li	s4,-1
    80004c7c:	b7d5                	j	80004c60 <filewrite+0xfa>
    panic("filewrite");
    80004c7e:	00004517          	auipc	a0,0x4
    80004c82:	a6250513          	addi	a0,a0,-1438 # 800086e0 <syscalls+0x280>
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	8b8080e7          	jalr	-1864(ra) # 8000053e <panic>
    return -1;
    80004c8e:	5a7d                	li	s4,-1
    80004c90:	bfc1                	j	80004c60 <filewrite+0xfa>
      return -1;
    80004c92:	5a7d                	li	s4,-1
    80004c94:	b7f1                	j	80004c60 <filewrite+0xfa>
    80004c96:	5a7d                	li	s4,-1
    80004c98:	b7e1                	j	80004c60 <filewrite+0xfa>

0000000080004c9a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c9a:	7179                	addi	sp,sp,-48
    80004c9c:	f406                	sd	ra,40(sp)
    80004c9e:	f022                	sd	s0,32(sp)
    80004ca0:	ec26                	sd	s1,24(sp)
    80004ca2:	e84a                	sd	s2,16(sp)
    80004ca4:	e44e                	sd	s3,8(sp)
    80004ca6:	e052                	sd	s4,0(sp)
    80004ca8:	1800                	addi	s0,sp,48
    80004caa:	84aa                	mv	s1,a0
    80004cac:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cae:	0005b023          	sd	zero,0(a1)
    80004cb2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cb6:	00000097          	auipc	ra,0x0
    80004cba:	bf8080e7          	jalr	-1032(ra) # 800048ae <filealloc>
    80004cbe:	e088                	sd	a0,0(s1)
    80004cc0:	c551                	beqz	a0,80004d4c <pipealloc+0xb2>
    80004cc2:	00000097          	auipc	ra,0x0
    80004cc6:	bec080e7          	jalr	-1044(ra) # 800048ae <filealloc>
    80004cca:	00aa3023          	sd	a0,0(s4)
    80004cce:	c92d                	beqz	a0,80004d40 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cd0:	ffffc097          	auipc	ra,0xffffc
    80004cd4:	e16080e7          	jalr	-490(ra) # 80000ae6 <kalloc>
    80004cd8:	892a                	mv	s2,a0
    80004cda:	c125                	beqz	a0,80004d3a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004cdc:	4985                	li	s3,1
    80004cde:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ce2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ce6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004cea:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004cee:	00004597          	auipc	a1,0x4
    80004cf2:	a0258593          	addi	a1,a1,-1534 # 800086f0 <syscalls+0x290>
    80004cf6:	ffffc097          	auipc	ra,0xffffc
    80004cfa:	e50080e7          	jalr	-432(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004cfe:	609c                	ld	a5,0(s1)
    80004d00:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d04:	609c                	ld	a5,0(s1)
    80004d06:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d0a:	609c                	ld	a5,0(s1)
    80004d0c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d10:	609c                	ld	a5,0(s1)
    80004d12:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d16:	000a3783          	ld	a5,0(s4)
    80004d1a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d1e:	000a3783          	ld	a5,0(s4)
    80004d22:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d26:	000a3783          	ld	a5,0(s4)
    80004d2a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d2e:	000a3783          	ld	a5,0(s4)
    80004d32:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d36:	4501                	li	a0,0
    80004d38:	a025                	j	80004d60 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d3a:	6088                	ld	a0,0(s1)
    80004d3c:	e501                	bnez	a0,80004d44 <pipealloc+0xaa>
    80004d3e:	a039                	j	80004d4c <pipealloc+0xb2>
    80004d40:	6088                	ld	a0,0(s1)
    80004d42:	c51d                	beqz	a0,80004d70 <pipealloc+0xd6>
    fileclose(*f0);
    80004d44:	00000097          	auipc	ra,0x0
    80004d48:	c26080e7          	jalr	-986(ra) # 8000496a <fileclose>
  if(*f1)
    80004d4c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d50:	557d                	li	a0,-1
  if(*f1)
    80004d52:	c799                	beqz	a5,80004d60 <pipealloc+0xc6>
    fileclose(*f1);
    80004d54:	853e                	mv	a0,a5
    80004d56:	00000097          	auipc	ra,0x0
    80004d5a:	c14080e7          	jalr	-1004(ra) # 8000496a <fileclose>
  return -1;
    80004d5e:	557d                	li	a0,-1
}
    80004d60:	70a2                	ld	ra,40(sp)
    80004d62:	7402                	ld	s0,32(sp)
    80004d64:	64e2                	ld	s1,24(sp)
    80004d66:	6942                	ld	s2,16(sp)
    80004d68:	69a2                	ld	s3,8(sp)
    80004d6a:	6a02                	ld	s4,0(sp)
    80004d6c:	6145                	addi	sp,sp,48
    80004d6e:	8082                	ret
  return -1;
    80004d70:	557d                	li	a0,-1
    80004d72:	b7fd                	j	80004d60 <pipealloc+0xc6>

0000000080004d74 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d74:	1101                	addi	sp,sp,-32
    80004d76:	ec06                	sd	ra,24(sp)
    80004d78:	e822                	sd	s0,16(sp)
    80004d7a:	e426                	sd	s1,8(sp)
    80004d7c:	e04a                	sd	s2,0(sp)
    80004d7e:	1000                	addi	s0,sp,32
    80004d80:	84aa                	mv	s1,a0
    80004d82:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	e52080e7          	jalr	-430(ra) # 80000bd6 <acquire>
  if(writable){
    80004d8c:	02090d63          	beqz	s2,80004dc6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004d90:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d94:	21848513          	addi	a0,s1,536
    80004d98:	ffffd097          	auipc	ra,0xffffd
    80004d9c:	44c080e7          	jalr	1100(ra) # 800021e4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004da0:	2204b783          	ld	a5,544(s1)
    80004da4:	eb95                	bnez	a5,80004dd8 <pipeclose+0x64>
    release(&pi->lock);
    80004da6:	8526                	mv	a0,s1
    80004da8:	ffffc097          	auipc	ra,0xffffc
    80004dac:	ee2080e7          	jalr	-286(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004db0:	8526                	mv	a0,s1
    80004db2:	ffffc097          	auipc	ra,0xffffc
    80004db6:	c38080e7          	jalr	-968(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004dba:	60e2                	ld	ra,24(sp)
    80004dbc:	6442                	ld	s0,16(sp)
    80004dbe:	64a2                	ld	s1,8(sp)
    80004dc0:	6902                	ld	s2,0(sp)
    80004dc2:	6105                	addi	sp,sp,32
    80004dc4:	8082                	ret
    pi->readopen = 0;
    80004dc6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004dca:	21c48513          	addi	a0,s1,540
    80004dce:	ffffd097          	auipc	ra,0xffffd
    80004dd2:	416080e7          	jalr	1046(ra) # 800021e4 <wakeup>
    80004dd6:	b7e9                	j	80004da0 <pipeclose+0x2c>
    release(&pi->lock);
    80004dd8:	8526                	mv	a0,s1
    80004dda:	ffffc097          	auipc	ra,0xffffc
    80004dde:	eb0080e7          	jalr	-336(ra) # 80000c8a <release>
}
    80004de2:	bfe1                	j	80004dba <pipeclose+0x46>

0000000080004de4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004de4:	711d                	addi	sp,sp,-96
    80004de6:	ec86                	sd	ra,88(sp)
    80004de8:	e8a2                	sd	s0,80(sp)
    80004dea:	e4a6                	sd	s1,72(sp)
    80004dec:	e0ca                	sd	s2,64(sp)
    80004dee:	fc4e                	sd	s3,56(sp)
    80004df0:	f852                	sd	s4,48(sp)
    80004df2:	f456                	sd	s5,40(sp)
    80004df4:	f05a                	sd	s6,32(sp)
    80004df6:	ec5e                	sd	s7,24(sp)
    80004df8:	e862                	sd	s8,16(sp)
    80004dfa:	1080                	addi	s0,sp,96
    80004dfc:	84aa                	mv	s1,a0
    80004dfe:	8aae                	mv	s5,a1
    80004e00:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e02:	ffffd097          	auipc	ra,0xffffd
    80004e06:	baa080e7          	jalr	-1110(ra) # 800019ac <myproc>
    80004e0a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e0c:	8526                	mv	a0,s1
    80004e0e:	ffffc097          	auipc	ra,0xffffc
    80004e12:	dc8080e7          	jalr	-568(ra) # 80000bd6 <acquire>
  while(i < n){
    80004e16:	0b405663          	blez	s4,80004ec2 <pipewrite+0xde>
  int i = 0;
    80004e1a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e1c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e1e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e22:	21c48b93          	addi	s7,s1,540
    80004e26:	a089                	j	80004e68 <pipewrite+0x84>
      release(&pi->lock);
    80004e28:	8526                	mv	a0,s1
    80004e2a:	ffffc097          	auipc	ra,0xffffc
    80004e2e:	e60080e7          	jalr	-416(ra) # 80000c8a <release>
      return -1;
    80004e32:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e34:	854a                	mv	a0,s2
    80004e36:	60e6                	ld	ra,88(sp)
    80004e38:	6446                	ld	s0,80(sp)
    80004e3a:	64a6                	ld	s1,72(sp)
    80004e3c:	6906                	ld	s2,64(sp)
    80004e3e:	79e2                	ld	s3,56(sp)
    80004e40:	7a42                	ld	s4,48(sp)
    80004e42:	7aa2                	ld	s5,40(sp)
    80004e44:	7b02                	ld	s6,32(sp)
    80004e46:	6be2                	ld	s7,24(sp)
    80004e48:	6c42                	ld	s8,16(sp)
    80004e4a:	6125                	addi	sp,sp,96
    80004e4c:	8082                	ret
      wakeup(&pi->nread);
    80004e4e:	8562                	mv	a0,s8
    80004e50:	ffffd097          	auipc	ra,0xffffd
    80004e54:	394080e7          	jalr	916(ra) # 800021e4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e58:	85a6                	mv	a1,s1
    80004e5a:	855e                	mv	a0,s7
    80004e5c:	ffffd097          	auipc	ra,0xffffd
    80004e60:	324080e7          	jalr	804(ra) # 80002180 <sleep>
  while(i < n){
    80004e64:	07495063          	bge	s2,s4,80004ec4 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004e68:	2204a783          	lw	a5,544(s1)
    80004e6c:	dfd5                	beqz	a5,80004e28 <pipewrite+0x44>
    80004e6e:	854e                	mv	a0,s3
    80004e70:	ffffd097          	auipc	ra,0xffffd
    80004e74:	5c4080e7          	jalr	1476(ra) # 80002434 <killed>
    80004e78:	f945                	bnez	a0,80004e28 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e7a:	2184a783          	lw	a5,536(s1)
    80004e7e:	21c4a703          	lw	a4,540(s1)
    80004e82:	2007879b          	addiw	a5,a5,512
    80004e86:	fcf704e3          	beq	a4,a5,80004e4e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e8a:	4685                	li	a3,1
    80004e8c:	01590633          	add	a2,s2,s5
    80004e90:	faf40593          	addi	a1,s0,-81
    80004e94:	0509b503          	ld	a0,80(s3)
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	85c080e7          	jalr	-1956(ra) # 800016f4 <copyin>
    80004ea0:	03650263          	beq	a0,s6,80004ec4 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ea4:	21c4a783          	lw	a5,540(s1)
    80004ea8:	0017871b          	addiw	a4,a5,1
    80004eac:	20e4ae23          	sw	a4,540(s1)
    80004eb0:	1ff7f793          	andi	a5,a5,511
    80004eb4:	97a6                	add	a5,a5,s1
    80004eb6:	faf44703          	lbu	a4,-81(s0)
    80004eba:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ebe:	2905                	addiw	s2,s2,1
    80004ec0:	b755                	j	80004e64 <pipewrite+0x80>
  int i = 0;
    80004ec2:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ec4:	21848513          	addi	a0,s1,536
    80004ec8:	ffffd097          	auipc	ra,0xffffd
    80004ecc:	31c080e7          	jalr	796(ra) # 800021e4 <wakeup>
  release(&pi->lock);
    80004ed0:	8526                	mv	a0,s1
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	db8080e7          	jalr	-584(ra) # 80000c8a <release>
  return i;
    80004eda:	bfa9                	j	80004e34 <pipewrite+0x50>

0000000080004edc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004edc:	715d                	addi	sp,sp,-80
    80004ede:	e486                	sd	ra,72(sp)
    80004ee0:	e0a2                	sd	s0,64(sp)
    80004ee2:	fc26                	sd	s1,56(sp)
    80004ee4:	f84a                	sd	s2,48(sp)
    80004ee6:	f44e                	sd	s3,40(sp)
    80004ee8:	f052                	sd	s4,32(sp)
    80004eea:	ec56                	sd	s5,24(sp)
    80004eec:	e85a                	sd	s6,16(sp)
    80004eee:	0880                	addi	s0,sp,80
    80004ef0:	84aa                	mv	s1,a0
    80004ef2:	892e                	mv	s2,a1
    80004ef4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ef6:	ffffd097          	auipc	ra,0xffffd
    80004efa:	ab6080e7          	jalr	-1354(ra) # 800019ac <myproc>
    80004efe:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f00:	8526                	mv	a0,s1
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	cd4080e7          	jalr	-812(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f0a:	2184a703          	lw	a4,536(s1)
    80004f0e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f12:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f16:	02f71763          	bne	a4,a5,80004f44 <piperead+0x68>
    80004f1a:	2244a783          	lw	a5,548(s1)
    80004f1e:	c39d                	beqz	a5,80004f44 <piperead+0x68>
    if(killed(pr)){
    80004f20:	8552                	mv	a0,s4
    80004f22:	ffffd097          	auipc	ra,0xffffd
    80004f26:	512080e7          	jalr	1298(ra) # 80002434 <killed>
    80004f2a:	e941                	bnez	a0,80004fba <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f2c:	85a6                	mv	a1,s1
    80004f2e:	854e                	mv	a0,s3
    80004f30:	ffffd097          	auipc	ra,0xffffd
    80004f34:	250080e7          	jalr	592(ra) # 80002180 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f38:	2184a703          	lw	a4,536(s1)
    80004f3c:	21c4a783          	lw	a5,540(s1)
    80004f40:	fcf70de3          	beq	a4,a5,80004f1a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f44:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f46:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f48:	05505363          	blez	s5,80004f8e <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004f4c:	2184a783          	lw	a5,536(s1)
    80004f50:	21c4a703          	lw	a4,540(s1)
    80004f54:	02f70d63          	beq	a4,a5,80004f8e <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f58:	0017871b          	addiw	a4,a5,1
    80004f5c:	20e4ac23          	sw	a4,536(s1)
    80004f60:	1ff7f793          	andi	a5,a5,511
    80004f64:	97a6                	add	a5,a5,s1
    80004f66:	0187c783          	lbu	a5,24(a5)
    80004f6a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f6e:	4685                	li	a3,1
    80004f70:	fbf40613          	addi	a2,s0,-65
    80004f74:	85ca                	mv	a1,s2
    80004f76:	050a3503          	ld	a0,80(s4)
    80004f7a:	ffffc097          	auipc	ra,0xffffc
    80004f7e:	6ee080e7          	jalr	1774(ra) # 80001668 <copyout>
    80004f82:	01650663          	beq	a0,s6,80004f8e <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f86:	2985                	addiw	s3,s3,1
    80004f88:	0905                	addi	s2,s2,1
    80004f8a:	fd3a91e3          	bne	s5,s3,80004f4c <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f8e:	21c48513          	addi	a0,s1,540
    80004f92:	ffffd097          	auipc	ra,0xffffd
    80004f96:	252080e7          	jalr	594(ra) # 800021e4 <wakeup>
  release(&pi->lock);
    80004f9a:	8526                	mv	a0,s1
    80004f9c:	ffffc097          	auipc	ra,0xffffc
    80004fa0:	cee080e7          	jalr	-786(ra) # 80000c8a <release>
  return i;
}
    80004fa4:	854e                	mv	a0,s3
    80004fa6:	60a6                	ld	ra,72(sp)
    80004fa8:	6406                	ld	s0,64(sp)
    80004faa:	74e2                	ld	s1,56(sp)
    80004fac:	7942                	ld	s2,48(sp)
    80004fae:	79a2                	ld	s3,40(sp)
    80004fb0:	7a02                	ld	s4,32(sp)
    80004fb2:	6ae2                	ld	s5,24(sp)
    80004fb4:	6b42                	ld	s6,16(sp)
    80004fb6:	6161                	addi	sp,sp,80
    80004fb8:	8082                	ret
      release(&pi->lock);
    80004fba:	8526                	mv	a0,s1
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	cce080e7          	jalr	-818(ra) # 80000c8a <release>
      return -1;
    80004fc4:	59fd                	li	s3,-1
    80004fc6:	bff9                	j	80004fa4 <piperead+0xc8>

0000000080004fc8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004fc8:	1141                	addi	sp,sp,-16
    80004fca:	e422                	sd	s0,8(sp)
    80004fcc:	0800                	addi	s0,sp,16
    80004fce:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004fd0:	8905                	andi	a0,a0,1
    80004fd2:	c111                	beqz	a0,80004fd6 <flags2perm+0xe>
      perm = PTE_X;
    80004fd4:	4521                	li	a0,8
    if(flags & 0x2)
    80004fd6:	8b89                	andi	a5,a5,2
    80004fd8:	c399                	beqz	a5,80004fde <flags2perm+0x16>
      perm |= PTE_W;
    80004fda:	00456513          	ori	a0,a0,4
    return perm;
}
    80004fde:	6422                	ld	s0,8(sp)
    80004fe0:	0141                	addi	sp,sp,16
    80004fe2:	8082                	ret

0000000080004fe4 <exec>:

int
exec(char *path, char **argv)
{
    80004fe4:	de010113          	addi	sp,sp,-544
    80004fe8:	20113c23          	sd	ra,536(sp)
    80004fec:	20813823          	sd	s0,528(sp)
    80004ff0:	20913423          	sd	s1,520(sp)
    80004ff4:	21213023          	sd	s2,512(sp)
    80004ff8:	ffce                	sd	s3,504(sp)
    80004ffa:	fbd2                	sd	s4,496(sp)
    80004ffc:	f7d6                	sd	s5,488(sp)
    80004ffe:	f3da                	sd	s6,480(sp)
    80005000:	efde                	sd	s7,472(sp)
    80005002:	ebe2                	sd	s8,464(sp)
    80005004:	e7e6                	sd	s9,456(sp)
    80005006:	e3ea                	sd	s10,448(sp)
    80005008:	ff6e                	sd	s11,440(sp)
    8000500a:	1400                	addi	s0,sp,544
    8000500c:	892a                	mv	s2,a0
    8000500e:	dea43423          	sd	a0,-536(s0)
    80005012:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005016:	ffffd097          	auipc	ra,0xffffd
    8000501a:	996080e7          	jalr	-1642(ra) # 800019ac <myproc>
    8000501e:	84aa                	mv	s1,a0

  begin_op();
    80005020:	fffff097          	auipc	ra,0xfffff
    80005024:	47e080e7          	jalr	1150(ra) # 8000449e <begin_op>

  if((ip = namei(path)) == 0){
    80005028:	854a                	mv	a0,s2
    8000502a:	fffff097          	auipc	ra,0xfffff
    8000502e:	258080e7          	jalr	600(ra) # 80004282 <namei>
    80005032:	c93d                	beqz	a0,800050a8 <exec+0xc4>
    80005034:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	aa6080e7          	jalr	-1370(ra) # 80003adc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000503e:	04000713          	li	a4,64
    80005042:	4681                	li	a3,0
    80005044:	e5040613          	addi	a2,s0,-432
    80005048:	4581                	li	a1,0
    8000504a:	8556                	mv	a0,s5
    8000504c:	fffff097          	auipc	ra,0xfffff
    80005050:	d44080e7          	jalr	-700(ra) # 80003d90 <readi>
    80005054:	04000793          	li	a5,64
    80005058:	00f51a63          	bne	a0,a5,8000506c <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000505c:	e5042703          	lw	a4,-432(s0)
    80005060:	464c47b7          	lui	a5,0x464c4
    80005064:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005068:	04f70663          	beq	a4,a5,800050b4 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000506c:	8556                	mv	a0,s5
    8000506e:	fffff097          	auipc	ra,0xfffff
    80005072:	cd0080e7          	jalr	-816(ra) # 80003d3e <iunlockput>
    end_op();
    80005076:	fffff097          	auipc	ra,0xfffff
    8000507a:	4a8080e7          	jalr	1192(ra) # 8000451e <end_op>
  }
  return -1;
    8000507e:	557d                	li	a0,-1
}
    80005080:	21813083          	ld	ra,536(sp)
    80005084:	21013403          	ld	s0,528(sp)
    80005088:	20813483          	ld	s1,520(sp)
    8000508c:	20013903          	ld	s2,512(sp)
    80005090:	79fe                	ld	s3,504(sp)
    80005092:	7a5e                	ld	s4,496(sp)
    80005094:	7abe                	ld	s5,488(sp)
    80005096:	7b1e                	ld	s6,480(sp)
    80005098:	6bfe                	ld	s7,472(sp)
    8000509a:	6c5e                	ld	s8,464(sp)
    8000509c:	6cbe                	ld	s9,456(sp)
    8000509e:	6d1e                	ld	s10,448(sp)
    800050a0:	7dfa                	ld	s11,440(sp)
    800050a2:	22010113          	addi	sp,sp,544
    800050a6:	8082                	ret
    end_op();
    800050a8:	fffff097          	auipc	ra,0xfffff
    800050ac:	476080e7          	jalr	1142(ra) # 8000451e <end_op>
    return -1;
    800050b0:	557d                	li	a0,-1
    800050b2:	b7f9                	j	80005080 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800050b4:	8526                	mv	a0,s1
    800050b6:	ffffd097          	auipc	ra,0xffffd
    800050ba:	9ba080e7          	jalr	-1606(ra) # 80001a70 <proc_pagetable>
    800050be:	8b2a                	mv	s6,a0
    800050c0:	d555                	beqz	a0,8000506c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050c2:	e7042783          	lw	a5,-400(s0)
    800050c6:	e8845703          	lhu	a4,-376(s0)
    800050ca:	c735                	beqz	a4,80005136 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050cc:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ce:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800050d2:	6a05                	lui	s4,0x1
    800050d4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800050d8:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800050dc:	6d85                	lui	s11,0x1
    800050de:	7d7d                	lui	s10,0xfffff
    800050e0:	a481                	j	80005320 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050e2:	00003517          	auipc	a0,0x3
    800050e6:	61650513          	addi	a0,a0,1558 # 800086f8 <syscalls+0x298>
    800050ea:	ffffb097          	auipc	ra,0xffffb
    800050ee:	454080e7          	jalr	1108(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050f2:	874a                	mv	a4,s2
    800050f4:	009c86bb          	addw	a3,s9,s1
    800050f8:	4581                	li	a1,0
    800050fa:	8556                	mv	a0,s5
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	c94080e7          	jalr	-876(ra) # 80003d90 <readi>
    80005104:	2501                	sext.w	a0,a0
    80005106:	1aa91a63          	bne	s2,a0,800052ba <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    8000510a:	009d84bb          	addw	s1,s11,s1
    8000510e:	013d09bb          	addw	s3,s10,s3
    80005112:	1f74f763          	bgeu	s1,s7,80005300 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80005116:	02049593          	slli	a1,s1,0x20
    8000511a:	9181                	srli	a1,a1,0x20
    8000511c:	95e2                	add	a1,a1,s8
    8000511e:	855a                	mv	a0,s6
    80005120:	ffffc097          	auipc	ra,0xffffc
    80005124:	f3c080e7          	jalr	-196(ra) # 8000105c <walkaddr>
    80005128:	862a                	mv	a2,a0
    if(pa == 0)
    8000512a:	dd45                	beqz	a0,800050e2 <exec+0xfe>
      n = PGSIZE;
    8000512c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000512e:	fd49f2e3          	bgeu	s3,s4,800050f2 <exec+0x10e>
      n = sz - i;
    80005132:	894e                	mv	s2,s3
    80005134:	bf7d                	j	800050f2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005136:	4901                	li	s2,0
  iunlockput(ip);
    80005138:	8556                	mv	a0,s5
    8000513a:	fffff097          	auipc	ra,0xfffff
    8000513e:	c04080e7          	jalr	-1020(ra) # 80003d3e <iunlockput>
  end_op();
    80005142:	fffff097          	auipc	ra,0xfffff
    80005146:	3dc080e7          	jalr	988(ra) # 8000451e <end_op>
  p = myproc();
    8000514a:	ffffd097          	auipc	ra,0xffffd
    8000514e:	862080e7          	jalr	-1950(ra) # 800019ac <myproc>
    80005152:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005154:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005158:	6785                	lui	a5,0x1
    8000515a:	17fd                	addi	a5,a5,-1
    8000515c:	993e                	add	s2,s2,a5
    8000515e:	77fd                	lui	a5,0xfffff
    80005160:	00f977b3          	and	a5,s2,a5
    80005164:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005168:	4691                	li	a3,4
    8000516a:	6609                	lui	a2,0x2
    8000516c:	963e                	add	a2,a2,a5
    8000516e:	85be                	mv	a1,a5
    80005170:	855a                	mv	a0,s6
    80005172:	ffffc097          	auipc	ra,0xffffc
    80005176:	29e080e7          	jalr	670(ra) # 80001410 <uvmalloc>
    8000517a:	8c2a                	mv	s8,a0
  ip = 0;
    8000517c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000517e:	12050e63          	beqz	a0,800052ba <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005182:	75f9                	lui	a1,0xffffe
    80005184:	95aa                	add	a1,a1,a0
    80005186:	855a                	mv	a0,s6
    80005188:	ffffc097          	auipc	ra,0xffffc
    8000518c:	4ae080e7          	jalr	1198(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    80005190:	7afd                	lui	s5,0xfffff
    80005192:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005194:	df043783          	ld	a5,-528(s0)
    80005198:	6388                	ld	a0,0(a5)
    8000519a:	c925                	beqz	a0,8000520a <exec+0x226>
    8000519c:	e9040993          	addi	s3,s0,-368
    800051a0:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051a4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051a6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051a8:	ffffc097          	auipc	ra,0xffffc
    800051ac:	ca6080e7          	jalr	-858(ra) # 80000e4e <strlen>
    800051b0:	0015079b          	addiw	a5,a0,1
    800051b4:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051b8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800051bc:	13596663          	bltu	s2,s5,800052e8 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051c0:	df043d83          	ld	s11,-528(s0)
    800051c4:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800051c8:	8552                	mv	a0,s4
    800051ca:	ffffc097          	auipc	ra,0xffffc
    800051ce:	c84080e7          	jalr	-892(ra) # 80000e4e <strlen>
    800051d2:	0015069b          	addiw	a3,a0,1
    800051d6:	8652                	mv	a2,s4
    800051d8:	85ca                	mv	a1,s2
    800051da:	855a                	mv	a0,s6
    800051dc:	ffffc097          	auipc	ra,0xffffc
    800051e0:	48c080e7          	jalr	1164(ra) # 80001668 <copyout>
    800051e4:	10054663          	bltz	a0,800052f0 <exec+0x30c>
    ustack[argc] = sp;
    800051e8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051ec:	0485                	addi	s1,s1,1
    800051ee:	008d8793          	addi	a5,s11,8
    800051f2:	def43823          	sd	a5,-528(s0)
    800051f6:	008db503          	ld	a0,8(s11)
    800051fa:	c911                	beqz	a0,8000520e <exec+0x22a>
    if(argc >= MAXARG)
    800051fc:	09a1                	addi	s3,s3,8
    800051fe:	fb3c95e3          	bne	s9,s3,800051a8 <exec+0x1c4>
  sz = sz1;
    80005202:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005206:	4a81                	li	s5,0
    80005208:	a84d                	j	800052ba <exec+0x2d6>
  sp = sz;
    8000520a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000520c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000520e:	00349793          	slli	a5,s1,0x3
    80005212:	f9040713          	addi	a4,s0,-112
    80005216:	97ba                	add	a5,a5,a4
    80005218:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdc790>
  sp -= (argc+1) * sizeof(uint64);
    8000521c:	00148693          	addi	a3,s1,1
    80005220:	068e                	slli	a3,a3,0x3
    80005222:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005226:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000522a:	01597663          	bgeu	s2,s5,80005236 <exec+0x252>
  sz = sz1;
    8000522e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005232:	4a81                	li	s5,0
    80005234:	a059                	j	800052ba <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005236:	e9040613          	addi	a2,s0,-368
    8000523a:	85ca                	mv	a1,s2
    8000523c:	855a                	mv	a0,s6
    8000523e:	ffffc097          	auipc	ra,0xffffc
    80005242:	42a080e7          	jalr	1066(ra) # 80001668 <copyout>
    80005246:	0a054963          	bltz	a0,800052f8 <exec+0x314>
  p->trapframe->a1 = sp;
    8000524a:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000524e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005252:	de843783          	ld	a5,-536(s0)
    80005256:	0007c703          	lbu	a4,0(a5)
    8000525a:	cf11                	beqz	a4,80005276 <exec+0x292>
    8000525c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000525e:	02f00693          	li	a3,47
    80005262:	a039                	j	80005270 <exec+0x28c>
      last = s+1;
    80005264:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005268:	0785                	addi	a5,a5,1
    8000526a:	fff7c703          	lbu	a4,-1(a5)
    8000526e:	c701                	beqz	a4,80005276 <exec+0x292>
    if(*s == '/')
    80005270:	fed71ce3          	bne	a4,a3,80005268 <exec+0x284>
    80005274:	bfc5                	j	80005264 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005276:	4641                	li	a2,16
    80005278:	de843583          	ld	a1,-536(s0)
    8000527c:	158b8513          	addi	a0,s7,344
    80005280:	ffffc097          	auipc	ra,0xffffc
    80005284:	b9c080e7          	jalr	-1124(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005288:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000528c:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005290:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005294:	058bb783          	ld	a5,88(s7)
    80005298:	e6843703          	ld	a4,-408(s0)
    8000529c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000529e:	058bb783          	ld	a5,88(s7)
    800052a2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052a6:	85ea                	mv	a1,s10
    800052a8:	ffffd097          	auipc	ra,0xffffd
    800052ac:	864080e7          	jalr	-1948(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052b0:	0004851b          	sext.w	a0,s1
    800052b4:	b3f1                	j	80005080 <exec+0x9c>
    800052b6:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800052ba:	df843583          	ld	a1,-520(s0)
    800052be:	855a                	mv	a0,s6
    800052c0:	ffffd097          	auipc	ra,0xffffd
    800052c4:	84c080e7          	jalr	-1972(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    800052c8:	da0a92e3          	bnez	s5,8000506c <exec+0x88>
  return -1;
    800052cc:	557d                	li	a0,-1
    800052ce:	bb4d                	j	80005080 <exec+0x9c>
    800052d0:	df243c23          	sd	s2,-520(s0)
    800052d4:	b7dd                	j	800052ba <exec+0x2d6>
    800052d6:	df243c23          	sd	s2,-520(s0)
    800052da:	b7c5                	j	800052ba <exec+0x2d6>
    800052dc:	df243c23          	sd	s2,-520(s0)
    800052e0:	bfe9                	j	800052ba <exec+0x2d6>
    800052e2:	df243c23          	sd	s2,-520(s0)
    800052e6:	bfd1                	j	800052ba <exec+0x2d6>
  sz = sz1;
    800052e8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052ec:	4a81                	li	s5,0
    800052ee:	b7f1                	j	800052ba <exec+0x2d6>
  sz = sz1;
    800052f0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052f4:	4a81                	li	s5,0
    800052f6:	b7d1                	j	800052ba <exec+0x2d6>
  sz = sz1;
    800052f8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052fc:	4a81                	li	s5,0
    800052fe:	bf75                	j	800052ba <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005300:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005304:	e0843783          	ld	a5,-504(s0)
    80005308:	0017869b          	addiw	a3,a5,1
    8000530c:	e0d43423          	sd	a3,-504(s0)
    80005310:	e0043783          	ld	a5,-512(s0)
    80005314:	0387879b          	addiw	a5,a5,56
    80005318:	e8845703          	lhu	a4,-376(s0)
    8000531c:	e0e6dee3          	bge	a3,a4,80005138 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005320:	2781                	sext.w	a5,a5
    80005322:	e0f43023          	sd	a5,-512(s0)
    80005326:	03800713          	li	a4,56
    8000532a:	86be                	mv	a3,a5
    8000532c:	e1840613          	addi	a2,s0,-488
    80005330:	4581                	li	a1,0
    80005332:	8556                	mv	a0,s5
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	a5c080e7          	jalr	-1444(ra) # 80003d90 <readi>
    8000533c:	03800793          	li	a5,56
    80005340:	f6f51be3          	bne	a0,a5,800052b6 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005344:	e1842783          	lw	a5,-488(s0)
    80005348:	4705                	li	a4,1
    8000534a:	fae79de3          	bne	a5,a4,80005304 <exec+0x320>
    if(ph.memsz < ph.filesz)
    8000534e:	e4043483          	ld	s1,-448(s0)
    80005352:	e3843783          	ld	a5,-456(s0)
    80005356:	f6f4ede3          	bltu	s1,a5,800052d0 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000535a:	e2843783          	ld	a5,-472(s0)
    8000535e:	94be                	add	s1,s1,a5
    80005360:	f6f4ebe3          	bltu	s1,a5,800052d6 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005364:	de043703          	ld	a4,-544(s0)
    80005368:	8ff9                	and	a5,a5,a4
    8000536a:	fbad                	bnez	a5,800052dc <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000536c:	e1c42503          	lw	a0,-484(s0)
    80005370:	00000097          	auipc	ra,0x0
    80005374:	c58080e7          	jalr	-936(ra) # 80004fc8 <flags2perm>
    80005378:	86aa                	mv	a3,a0
    8000537a:	8626                	mv	a2,s1
    8000537c:	85ca                	mv	a1,s2
    8000537e:	855a                	mv	a0,s6
    80005380:	ffffc097          	auipc	ra,0xffffc
    80005384:	090080e7          	jalr	144(ra) # 80001410 <uvmalloc>
    80005388:	dea43c23          	sd	a0,-520(s0)
    8000538c:	d939                	beqz	a0,800052e2 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000538e:	e2843c03          	ld	s8,-472(s0)
    80005392:	e2042c83          	lw	s9,-480(s0)
    80005396:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000539a:	f60b83e3          	beqz	s7,80005300 <exec+0x31c>
    8000539e:	89de                	mv	s3,s7
    800053a0:	4481                	li	s1,0
    800053a2:	bb95                	j	80005116 <exec+0x132>

00000000800053a4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053a4:	7179                	addi	sp,sp,-48
    800053a6:	f406                	sd	ra,40(sp)
    800053a8:	f022                	sd	s0,32(sp)
    800053aa:	ec26                	sd	s1,24(sp)
    800053ac:	e84a                	sd	s2,16(sp)
    800053ae:	1800                	addi	s0,sp,48
    800053b0:	892e                	mv	s2,a1
    800053b2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800053b4:	fdc40593          	addi	a1,s0,-36
    800053b8:	ffffe097          	auipc	ra,0xffffe
    800053bc:	a5e080e7          	jalr	-1442(ra) # 80002e16 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053c0:	fdc42703          	lw	a4,-36(s0)
    800053c4:	47bd                	li	a5,15
    800053c6:	02e7eb63          	bltu	a5,a4,800053fc <argfd+0x58>
    800053ca:	ffffc097          	auipc	ra,0xffffc
    800053ce:	5e2080e7          	jalr	1506(ra) # 800019ac <myproc>
    800053d2:	fdc42703          	lw	a4,-36(s0)
    800053d6:	01a70793          	addi	a5,a4,26
    800053da:	078e                	slli	a5,a5,0x3
    800053dc:	953e                	add	a0,a0,a5
    800053de:	611c                	ld	a5,0(a0)
    800053e0:	c385                	beqz	a5,80005400 <argfd+0x5c>
    return -1;
  if(pfd)
    800053e2:	00090463          	beqz	s2,800053ea <argfd+0x46>
    *pfd = fd;
    800053e6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053ea:	4501                	li	a0,0
  if(pf)
    800053ec:	c091                	beqz	s1,800053f0 <argfd+0x4c>
    *pf = f;
    800053ee:	e09c                	sd	a5,0(s1)
}
    800053f0:	70a2                	ld	ra,40(sp)
    800053f2:	7402                	ld	s0,32(sp)
    800053f4:	64e2                	ld	s1,24(sp)
    800053f6:	6942                	ld	s2,16(sp)
    800053f8:	6145                	addi	sp,sp,48
    800053fa:	8082                	ret
    return -1;
    800053fc:	557d                	li	a0,-1
    800053fe:	bfcd                	j	800053f0 <argfd+0x4c>
    80005400:	557d                	li	a0,-1
    80005402:	b7fd                	j	800053f0 <argfd+0x4c>

0000000080005404 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005404:	1101                	addi	sp,sp,-32
    80005406:	ec06                	sd	ra,24(sp)
    80005408:	e822                	sd	s0,16(sp)
    8000540a:	e426                	sd	s1,8(sp)
    8000540c:	1000                	addi	s0,sp,32
    8000540e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005410:	ffffc097          	auipc	ra,0xffffc
    80005414:	59c080e7          	jalr	1436(ra) # 800019ac <myproc>
    80005418:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000541a:	0d050793          	addi	a5,a0,208
    8000541e:	4501                	li	a0,0
    80005420:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005422:	6398                	ld	a4,0(a5)
    80005424:	cb19                	beqz	a4,8000543a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005426:	2505                	addiw	a0,a0,1
    80005428:	07a1                	addi	a5,a5,8
    8000542a:	fed51ce3          	bne	a0,a3,80005422 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000542e:	557d                	li	a0,-1
}
    80005430:	60e2                	ld	ra,24(sp)
    80005432:	6442                	ld	s0,16(sp)
    80005434:	64a2                	ld	s1,8(sp)
    80005436:	6105                	addi	sp,sp,32
    80005438:	8082                	ret
      p->ofile[fd] = f;
    8000543a:	01a50793          	addi	a5,a0,26
    8000543e:	078e                	slli	a5,a5,0x3
    80005440:	963e                	add	a2,a2,a5
    80005442:	e204                	sd	s1,0(a2)
      return fd;
    80005444:	b7f5                	j	80005430 <fdalloc+0x2c>

0000000080005446 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005446:	715d                	addi	sp,sp,-80
    80005448:	e486                	sd	ra,72(sp)
    8000544a:	e0a2                	sd	s0,64(sp)
    8000544c:	fc26                	sd	s1,56(sp)
    8000544e:	f84a                	sd	s2,48(sp)
    80005450:	f44e                	sd	s3,40(sp)
    80005452:	f052                	sd	s4,32(sp)
    80005454:	ec56                	sd	s5,24(sp)
    80005456:	e85a                	sd	s6,16(sp)
    80005458:	0880                	addi	s0,sp,80
    8000545a:	8b2e                	mv	s6,a1
    8000545c:	89b2                	mv	s3,a2
    8000545e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005460:	fb040593          	addi	a1,s0,-80
    80005464:	fffff097          	auipc	ra,0xfffff
    80005468:	e3c080e7          	jalr	-452(ra) # 800042a0 <nameiparent>
    8000546c:	84aa                	mv	s1,a0
    8000546e:	14050f63          	beqz	a0,800055cc <create+0x186>
    return 0;

  ilock(dp);
    80005472:	ffffe097          	auipc	ra,0xffffe
    80005476:	66a080e7          	jalr	1642(ra) # 80003adc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000547a:	4601                	li	a2,0
    8000547c:	fb040593          	addi	a1,s0,-80
    80005480:	8526                	mv	a0,s1
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	b3e080e7          	jalr	-1218(ra) # 80003fc0 <dirlookup>
    8000548a:	8aaa                	mv	s5,a0
    8000548c:	c931                	beqz	a0,800054e0 <create+0x9a>
    iunlockput(dp);
    8000548e:	8526                	mv	a0,s1
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	8ae080e7          	jalr	-1874(ra) # 80003d3e <iunlockput>
    ilock(ip);
    80005498:	8556                	mv	a0,s5
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	642080e7          	jalr	1602(ra) # 80003adc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054a2:	000b059b          	sext.w	a1,s6
    800054a6:	4789                	li	a5,2
    800054a8:	02f59563          	bne	a1,a5,800054d2 <create+0x8c>
    800054ac:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc8d4>
    800054b0:	37f9                	addiw	a5,a5,-2
    800054b2:	17c2                	slli	a5,a5,0x30
    800054b4:	93c1                	srli	a5,a5,0x30
    800054b6:	4705                	li	a4,1
    800054b8:	00f76d63          	bltu	a4,a5,800054d2 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800054bc:	8556                	mv	a0,s5
    800054be:	60a6                	ld	ra,72(sp)
    800054c0:	6406                	ld	s0,64(sp)
    800054c2:	74e2                	ld	s1,56(sp)
    800054c4:	7942                	ld	s2,48(sp)
    800054c6:	79a2                	ld	s3,40(sp)
    800054c8:	7a02                	ld	s4,32(sp)
    800054ca:	6ae2                	ld	s5,24(sp)
    800054cc:	6b42                	ld	s6,16(sp)
    800054ce:	6161                	addi	sp,sp,80
    800054d0:	8082                	ret
    iunlockput(ip);
    800054d2:	8556                	mv	a0,s5
    800054d4:	fffff097          	auipc	ra,0xfffff
    800054d8:	86a080e7          	jalr	-1942(ra) # 80003d3e <iunlockput>
    return 0;
    800054dc:	4a81                	li	s5,0
    800054de:	bff9                	j	800054bc <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800054e0:	85da                	mv	a1,s6
    800054e2:	4088                	lw	a0,0(s1)
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	45c080e7          	jalr	1116(ra) # 80003940 <ialloc>
    800054ec:	8a2a                	mv	s4,a0
    800054ee:	c539                	beqz	a0,8000553c <create+0xf6>
  ilock(ip);
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	5ec080e7          	jalr	1516(ra) # 80003adc <ilock>
  ip->major = major;
    800054f8:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800054fc:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005500:	4905                	li	s2,1
    80005502:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005506:	8552                	mv	a0,s4
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	50a080e7          	jalr	1290(ra) # 80003a12 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005510:	000b059b          	sext.w	a1,s6
    80005514:	03258b63          	beq	a1,s2,8000554a <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005518:	004a2603          	lw	a2,4(s4)
    8000551c:	fb040593          	addi	a1,s0,-80
    80005520:	8526                	mv	a0,s1
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	cae080e7          	jalr	-850(ra) # 800041d0 <dirlink>
    8000552a:	06054f63          	bltz	a0,800055a8 <create+0x162>
  iunlockput(dp);
    8000552e:	8526                	mv	a0,s1
    80005530:	fffff097          	auipc	ra,0xfffff
    80005534:	80e080e7          	jalr	-2034(ra) # 80003d3e <iunlockput>
  return ip;
    80005538:	8ad2                	mv	s5,s4
    8000553a:	b749                	j	800054bc <create+0x76>
    iunlockput(dp);
    8000553c:	8526                	mv	a0,s1
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	800080e7          	jalr	-2048(ra) # 80003d3e <iunlockput>
    return 0;
    80005546:	8ad2                	mv	s5,s4
    80005548:	bf95                	j	800054bc <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000554a:	004a2603          	lw	a2,4(s4)
    8000554e:	00003597          	auipc	a1,0x3
    80005552:	1ca58593          	addi	a1,a1,458 # 80008718 <syscalls+0x2b8>
    80005556:	8552                	mv	a0,s4
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	c78080e7          	jalr	-904(ra) # 800041d0 <dirlink>
    80005560:	04054463          	bltz	a0,800055a8 <create+0x162>
    80005564:	40d0                	lw	a2,4(s1)
    80005566:	00003597          	auipc	a1,0x3
    8000556a:	1ba58593          	addi	a1,a1,442 # 80008720 <syscalls+0x2c0>
    8000556e:	8552                	mv	a0,s4
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	c60080e7          	jalr	-928(ra) # 800041d0 <dirlink>
    80005578:	02054863          	bltz	a0,800055a8 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000557c:	004a2603          	lw	a2,4(s4)
    80005580:	fb040593          	addi	a1,s0,-80
    80005584:	8526                	mv	a0,s1
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	c4a080e7          	jalr	-950(ra) # 800041d0 <dirlink>
    8000558e:	00054d63          	bltz	a0,800055a8 <create+0x162>
    dp->nlink++;  // for ".."
    80005592:	04a4d783          	lhu	a5,74(s1)
    80005596:	2785                	addiw	a5,a5,1
    80005598:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000559c:	8526                	mv	a0,s1
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	474080e7          	jalr	1140(ra) # 80003a12 <iupdate>
    800055a6:	b761                	j	8000552e <create+0xe8>
  ip->nlink = 0;
    800055a8:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800055ac:	8552                	mv	a0,s4
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	464080e7          	jalr	1124(ra) # 80003a12 <iupdate>
  iunlockput(ip);
    800055b6:	8552                	mv	a0,s4
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	786080e7          	jalr	1926(ra) # 80003d3e <iunlockput>
  iunlockput(dp);
    800055c0:	8526                	mv	a0,s1
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	77c080e7          	jalr	1916(ra) # 80003d3e <iunlockput>
  return 0;
    800055ca:	bdcd                	j	800054bc <create+0x76>
    return 0;
    800055cc:	8aaa                	mv	s5,a0
    800055ce:	b5fd                	j	800054bc <create+0x76>

00000000800055d0 <sys_dup>:
{
    800055d0:	7179                	addi	sp,sp,-48
    800055d2:	f406                	sd	ra,40(sp)
    800055d4:	f022                	sd	s0,32(sp)
    800055d6:	ec26                	sd	s1,24(sp)
    800055d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055da:	fd840613          	addi	a2,s0,-40
    800055de:	4581                	li	a1,0
    800055e0:	4501                	li	a0,0
    800055e2:	00000097          	auipc	ra,0x0
    800055e6:	dc2080e7          	jalr	-574(ra) # 800053a4 <argfd>
    return -1;
    800055ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800055ec:	02054363          	bltz	a0,80005612 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800055f0:	fd843503          	ld	a0,-40(s0)
    800055f4:	00000097          	auipc	ra,0x0
    800055f8:	e10080e7          	jalr	-496(ra) # 80005404 <fdalloc>
    800055fc:	84aa                	mv	s1,a0
    return -1;
    800055fe:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005600:	00054963          	bltz	a0,80005612 <sys_dup+0x42>
  filedup(f);
    80005604:	fd843503          	ld	a0,-40(s0)
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	310080e7          	jalr	784(ra) # 80004918 <filedup>
  return fd;
    80005610:	87a6                	mv	a5,s1
}
    80005612:	853e                	mv	a0,a5
    80005614:	70a2                	ld	ra,40(sp)
    80005616:	7402                	ld	s0,32(sp)
    80005618:	64e2                	ld	s1,24(sp)
    8000561a:	6145                	addi	sp,sp,48
    8000561c:	8082                	ret

000000008000561e <sys_getreadcount>:
{
    8000561e:	1141                	addi	sp,sp,-16
    80005620:	e422                	sd	s0,8(sp)
    80005622:	0800                	addi	s0,sp,16
}
    80005624:	00003517          	auipc	a0,0x3
    80005628:	2d052503          	lw	a0,720(a0) # 800088f4 <readCount>
    8000562c:	6422                	ld	s0,8(sp)
    8000562e:	0141                	addi	sp,sp,16
    80005630:	8082                	ret

0000000080005632 <sys_read>:
{
    80005632:	7179                	addi	sp,sp,-48
    80005634:	f406                	sd	ra,40(sp)
    80005636:	f022                	sd	s0,32(sp)
    80005638:	1800                	addi	s0,sp,48
  readCount++;
    8000563a:	00003717          	auipc	a4,0x3
    8000563e:	2ba70713          	addi	a4,a4,698 # 800088f4 <readCount>
    80005642:	431c                	lw	a5,0(a4)
    80005644:	2785                	addiw	a5,a5,1
    80005646:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    80005648:	fd840593          	addi	a1,s0,-40
    8000564c:	4505                	li	a0,1
    8000564e:	ffffd097          	auipc	ra,0xffffd
    80005652:	7e8080e7          	jalr	2024(ra) # 80002e36 <argaddr>
  argint(2, &n);
    80005656:	fe440593          	addi	a1,s0,-28
    8000565a:	4509                	li	a0,2
    8000565c:	ffffd097          	auipc	ra,0xffffd
    80005660:	7ba080e7          	jalr	1978(ra) # 80002e16 <argint>
  if(argfd(0, 0, &f) < 0)
    80005664:	fe840613          	addi	a2,s0,-24
    80005668:	4581                	li	a1,0
    8000566a:	4501                	li	a0,0
    8000566c:	00000097          	auipc	ra,0x0
    80005670:	d38080e7          	jalr	-712(ra) # 800053a4 <argfd>
    80005674:	87aa                	mv	a5,a0
    return -1;
    80005676:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005678:	0007cc63          	bltz	a5,80005690 <sys_read+0x5e>
  return fileread(f, p, n);
    8000567c:	fe442603          	lw	a2,-28(s0)
    80005680:	fd843583          	ld	a1,-40(s0)
    80005684:	fe843503          	ld	a0,-24(s0)
    80005688:	fffff097          	auipc	ra,0xfffff
    8000568c:	41c080e7          	jalr	1052(ra) # 80004aa4 <fileread>
}
    80005690:	70a2                	ld	ra,40(sp)
    80005692:	7402                	ld	s0,32(sp)
    80005694:	6145                	addi	sp,sp,48
    80005696:	8082                	ret

0000000080005698 <sys_write>:
{
    80005698:	7179                	addi	sp,sp,-48
    8000569a:	f406                	sd	ra,40(sp)
    8000569c:	f022                	sd	s0,32(sp)
    8000569e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800056a0:	fd840593          	addi	a1,s0,-40
    800056a4:	4505                	li	a0,1
    800056a6:	ffffd097          	auipc	ra,0xffffd
    800056aa:	790080e7          	jalr	1936(ra) # 80002e36 <argaddr>
  argint(2, &n);
    800056ae:	fe440593          	addi	a1,s0,-28
    800056b2:	4509                	li	a0,2
    800056b4:	ffffd097          	auipc	ra,0xffffd
    800056b8:	762080e7          	jalr	1890(ra) # 80002e16 <argint>
  if(argfd(0, 0, &f) < 0)
    800056bc:	fe840613          	addi	a2,s0,-24
    800056c0:	4581                	li	a1,0
    800056c2:	4501                	li	a0,0
    800056c4:	00000097          	auipc	ra,0x0
    800056c8:	ce0080e7          	jalr	-800(ra) # 800053a4 <argfd>
    800056cc:	87aa                	mv	a5,a0
    return -1;
    800056ce:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056d0:	0007cc63          	bltz	a5,800056e8 <sys_write+0x50>
  return filewrite(f, p, n);
    800056d4:	fe442603          	lw	a2,-28(s0)
    800056d8:	fd843583          	ld	a1,-40(s0)
    800056dc:	fe843503          	ld	a0,-24(s0)
    800056e0:	fffff097          	auipc	ra,0xfffff
    800056e4:	486080e7          	jalr	1158(ra) # 80004b66 <filewrite>
}
    800056e8:	70a2                	ld	ra,40(sp)
    800056ea:	7402                	ld	s0,32(sp)
    800056ec:	6145                	addi	sp,sp,48
    800056ee:	8082                	ret

00000000800056f0 <sys_close>:
{
    800056f0:	1101                	addi	sp,sp,-32
    800056f2:	ec06                	sd	ra,24(sp)
    800056f4:	e822                	sd	s0,16(sp)
    800056f6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800056f8:	fe040613          	addi	a2,s0,-32
    800056fc:	fec40593          	addi	a1,s0,-20
    80005700:	4501                	li	a0,0
    80005702:	00000097          	auipc	ra,0x0
    80005706:	ca2080e7          	jalr	-862(ra) # 800053a4 <argfd>
    return -1;
    8000570a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000570c:	02054463          	bltz	a0,80005734 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005710:	ffffc097          	auipc	ra,0xffffc
    80005714:	29c080e7          	jalr	668(ra) # 800019ac <myproc>
    80005718:	fec42783          	lw	a5,-20(s0)
    8000571c:	07e9                	addi	a5,a5,26
    8000571e:	078e                	slli	a5,a5,0x3
    80005720:	97aa                	add	a5,a5,a0
    80005722:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005726:	fe043503          	ld	a0,-32(s0)
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	240080e7          	jalr	576(ra) # 8000496a <fileclose>
  return 0;
    80005732:	4781                	li	a5,0
}
    80005734:	853e                	mv	a0,a5
    80005736:	60e2                	ld	ra,24(sp)
    80005738:	6442                	ld	s0,16(sp)
    8000573a:	6105                	addi	sp,sp,32
    8000573c:	8082                	ret

000000008000573e <sys_fstat>:
{
    8000573e:	1101                	addi	sp,sp,-32
    80005740:	ec06                	sd	ra,24(sp)
    80005742:	e822                	sd	s0,16(sp)
    80005744:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005746:	fe040593          	addi	a1,s0,-32
    8000574a:	4505                	li	a0,1
    8000574c:	ffffd097          	auipc	ra,0xffffd
    80005750:	6ea080e7          	jalr	1770(ra) # 80002e36 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005754:	fe840613          	addi	a2,s0,-24
    80005758:	4581                	li	a1,0
    8000575a:	4501                	li	a0,0
    8000575c:	00000097          	auipc	ra,0x0
    80005760:	c48080e7          	jalr	-952(ra) # 800053a4 <argfd>
    80005764:	87aa                	mv	a5,a0
    return -1;
    80005766:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005768:	0007ca63          	bltz	a5,8000577c <sys_fstat+0x3e>
  return filestat(f, st);
    8000576c:	fe043583          	ld	a1,-32(s0)
    80005770:	fe843503          	ld	a0,-24(s0)
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	2be080e7          	jalr	702(ra) # 80004a32 <filestat>
}
    8000577c:	60e2                	ld	ra,24(sp)
    8000577e:	6442                	ld	s0,16(sp)
    80005780:	6105                	addi	sp,sp,32
    80005782:	8082                	ret

0000000080005784 <sys_link>:
{
    80005784:	7169                	addi	sp,sp,-304
    80005786:	f606                	sd	ra,296(sp)
    80005788:	f222                	sd	s0,288(sp)
    8000578a:	ee26                	sd	s1,280(sp)
    8000578c:	ea4a                	sd	s2,272(sp)
    8000578e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005790:	08000613          	li	a2,128
    80005794:	ed040593          	addi	a1,s0,-304
    80005798:	4501                	li	a0,0
    8000579a:	ffffd097          	auipc	ra,0xffffd
    8000579e:	6bc080e7          	jalr	1724(ra) # 80002e56 <argstr>
    return -1;
    800057a2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057a4:	10054e63          	bltz	a0,800058c0 <sys_link+0x13c>
    800057a8:	08000613          	li	a2,128
    800057ac:	f5040593          	addi	a1,s0,-176
    800057b0:	4505                	li	a0,1
    800057b2:	ffffd097          	auipc	ra,0xffffd
    800057b6:	6a4080e7          	jalr	1700(ra) # 80002e56 <argstr>
    return -1;
    800057ba:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057bc:	10054263          	bltz	a0,800058c0 <sys_link+0x13c>
  begin_op();
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	cde080e7          	jalr	-802(ra) # 8000449e <begin_op>
  if((ip = namei(old)) == 0){
    800057c8:	ed040513          	addi	a0,s0,-304
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	ab6080e7          	jalr	-1354(ra) # 80004282 <namei>
    800057d4:	84aa                	mv	s1,a0
    800057d6:	c551                	beqz	a0,80005862 <sys_link+0xde>
  ilock(ip);
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	304080e7          	jalr	772(ra) # 80003adc <ilock>
  if(ip->type == T_DIR){
    800057e0:	04449703          	lh	a4,68(s1)
    800057e4:	4785                	li	a5,1
    800057e6:	08f70463          	beq	a4,a5,8000586e <sys_link+0xea>
  ip->nlink++;
    800057ea:	04a4d783          	lhu	a5,74(s1)
    800057ee:	2785                	addiw	a5,a5,1
    800057f0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057f4:	8526                	mv	a0,s1
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	21c080e7          	jalr	540(ra) # 80003a12 <iupdate>
  iunlock(ip);
    800057fe:	8526                	mv	a0,s1
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	39e080e7          	jalr	926(ra) # 80003b9e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005808:	fd040593          	addi	a1,s0,-48
    8000580c:	f5040513          	addi	a0,s0,-176
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	a90080e7          	jalr	-1392(ra) # 800042a0 <nameiparent>
    80005818:	892a                	mv	s2,a0
    8000581a:	c935                	beqz	a0,8000588e <sys_link+0x10a>
  ilock(dp);
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	2c0080e7          	jalr	704(ra) # 80003adc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005824:	00092703          	lw	a4,0(s2)
    80005828:	409c                	lw	a5,0(s1)
    8000582a:	04f71d63          	bne	a4,a5,80005884 <sys_link+0x100>
    8000582e:	40d0                	lw	a2,4(s1)
    80005830:	fd040593          	addi	a1,s0,-48
    80005834:	854a                	mv	a0,s2
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	99a080e7          	jalr	-1638(ra) # 800041d0 <dirlink>
    8000583e:	04054363          	bltz	a0,80005884 <sys_link+0x100>
  iunlockput(dp);
    80005842:	854a                	mv	a0,s2
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	4fa080e7          	jalr	1274(ra) # 80003d3e <iunlockput>
  iput(ip);
    8000584c:	8526                	mv	a0,s1
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	448080e7          	jalr	1096(ra) # 80003c96 <iput>
  end_op();
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	cc8080e7          	jalr	-824(ra) # 8000451e <end_op>
  return 0;
    8000585e:	4781                	li	a5,0
    80005860:	a085                	j	800058c0 <sys_link+0x13c>
    end_op();
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	cbc080e7          	jalr	-836(ra) # 8000451e <end_op>
    return -1;
    8000586a:	57fd                	li	a5,-1
    8000586c:	a891                	j	800058c0 <sys_link+0x13c>
    iunlockput(ip);
    8000586e:	8526                	mv	a0,s1
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	4ce080e7          	jalr	1230(ra) # 80003d3e <iunlockput>
    end_op();
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	ca6080e7          	jalr	-858(ra) # 8000451e <end_op>
    return -1;
    80005880:	57fd                	li	a5,-1
    80005882:	a83d                	j	800058c0 <sys_link+0x13c>
    iunlockput(dp);
    80005884:	854a                	mv	a0,s2
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	4b8080e7          	jalr	1208(ra) # 80003d3e <iunlockput>
  ilock(ip);
    8000588e:	8526                	mv	a0,s1
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	24c080e7          	jalr	588(ra) # 80003adc <ilock>
  ip->nlink--;
    80005898:	04a4d783          	lhu	a5,74(s1)
    8000589c:	37fd                	addiw	a5,a5,-1
    8000589e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058a2:	8526                	mv	a0,s1
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	16e080e7          	jalr	366(ra) # 80003a12 <iupdate>
  iunlockput(ip);
    800058ac:	8526                	mv	a0,s1
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	490080e7          	jalr	1168(ra) # 80003d3e <iunlockput>
  end_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	c68080e7          	jalr	-920(ra) # 8000451e <end_op>
  return -1;
    800058be:	57fd                	li	a5,-1
}
    800058c0:	853e                	mv	a0,a5
    800058c2:	70b2                	ld	ra,296(sp)
    800058c4:	7412                	ld	s0,288(sp)
    800058c6:	64f2                	ld	s1,280(sp)
    800058c8:	6952                	ld	s2,272(sp)
    800058ca:	6155                	addi	sp,sp,304
    800058cc:	8082                	ret

00000000800058ce <sys_unlink>:
{
    800058ce:	7151                	addi	sp,sp,-240
    800058d0:	f586                	sd	ra,232(sp)
    800058d2:	f1a2                	sd	s0,224(sp)
    800058d4:	eda6                	sd	s1,216(sp)
    800058d6:	e9ca                	sd	s2,208(sp)
    800058d8:	e5ce                	sd	s3,200(sp)
    800058da:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058dc:	08000613          	li	a2,128
    800058e0:	f3040593          	addi	a1,s0,-208
    800058e4:	4501                	li	a0,0
    800058e6:	ffffd097          	auipc	ra,0xffffd
    800058ea:	570080e7          	jalr	1392(ra) # 80002e56 <argstr>
    800058ee:	18054163          	bltz	a0,80005a70 <sys_unlink+0x1a2>
  begin_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	bac080e7          	jalr	-1108(ra) # 8000449e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058fa:	fb040593          	addi	a1,s0,-80
    800058fe:	f3040513          	addi	a0,s0,-208
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	99e080e7          	jalr	-1634(ra) # 800042a0 <nameiparent>
    8000590a:	84aa                	mv	s1,a0
    8000590c:	c979                	beqz	a0,800059e2 <sys_unlink+0x114>
  ilock(dp);
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	1ce080e7          	jalr	462(ra) # 80003adc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005916:	00003597          	auipc	a1,0x3
    8000591a:	e0258593          	addi	a1,a1,-510 # 80008718 <syscalls+0x2b8>
    8000591e:	fb040513          	addi	a0,s0,-80
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	684080e7          	jalr	1668(ra) # 80003fa6 <namecmp>
    8000592a:	14050a63          	beqz	a0,80005a7e <sys_unlink+0x1b0>
    8000592e:	00003597          	auipc	a1,0x3
    80005932:	df258593          	addi	a1,a1,-526 # 80008720 <syscalls+0x2c0>
    80005936:	fb040513          	addi	a0,s0,-80
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	66c080e7          	jalr	1644(ra) # 80003fa6 <namecmp>
    80005942:	12050e63          	beqz	a0,80005a7e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005946:	f2c40613          	addi	a2,s0,-212
    8000594a:	fb040593          	addi	a1,s0,-80
    8000594e:	8526                	mv	a0,s1
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	670080e7          	jalr	1648(ra) # 80003fc0 <dirlookup>
    80005958:	892a                	mv	s2,a0
    8000595a:	12050263          	beqz	a0,80005a7e <sys_unlink+0x1b0>
  ilock(ip);
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	17e080e7          	jalr	382(ra) # 80003adc <ilock>
  if(ip->nlink < 1)
    80005966:	04a91783          	lh	a5,74(s2)
    8000596a:	08f05263          	blez	a5,800059ee <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000596e:	04491703          	lh	a4,68(s2)
    80005972:	4785                	li	a5,1
    80005974:	08f70563          	beq	a4,a5,800059fe <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005978:	4641                	li	a2,16
    8000597a:	4581                	li	a1,0
    8000597c:	fc040513          	addi	a0,s0,-64
    80005980:	ffffb097          	auipc	ra,0xffffb
    80005984:	352080e7          	jalr	850(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005988:	4741                	li	a4,16
    8000598a:	f2c42683          	lw	a3,-212(s0)
    8000598e:	fc040613          	addi	a2,s0,-64
    80005992:	4581                	li	a1,0
    80005994:	8526                	mv	a0,s1
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	4f2080e7          	jalr	1266(ra) # 80003e88 <writei>
    8000599e:	47c1                	li	a5,16
    800059a0:	0af51563          	bne	a0,a5,80005a4a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059a4:	04491703          	lh	a4,68(s2)
    800059a8:	4785                	li	a5,1
    800059aa:	0af70863          	beq	a4,a5,80005a5a <sys_unlink+0x18c>
  iunlockput(dp);
    800059ae:	8526                	mv	a0,s1
    800059b0:	ffffe097          	auipc	ra,0xffffe
    800059b4:	38e080e7          	jalr	910(ra) # 80003d3e <iunlockput>
  ip->nlink--;
    800059b8:	04a95783          	lhu	a5,74(s2)
    800059bc:	37fd                	addiw	a5,a5,-1
    800059be:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059c2:	854a                	mv	a0,s2
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	04e080e7          	jalr	78(ra) # 80003a12 <iupdate>
  iunlockput(ip);
    800059cc:	854a                	mv	a0,s2
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	370080e7          	jalr	880(ra) # 80003d3e <iunlockput>
  end_op();
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	b48080e7          	jalr	-1208(ra) # 8000451e <end_op>
  return 0;
    800059de:	4501                	li	a0,0
    800059e0:	a84d                	j	80005a92 <sys_unlink+0x1c4>
    end_op();
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	b3c080e7          	jalr	-1220(ra) # 8000451e <end_op>
    return -1;
    800059ea:	557d                	li	a0,-1
    800059ec:	a05d                	j	80005a92 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059ee:	00003517          	auipc	a0,0x3
    800059f2:	d3a50513          	addi	a0,a0,-710 # 80008728 <syscalls+0x2c8>
    800059f6:	ffffb097          	auipc	ra,0xffffb
    800059fa:	b48080e7          	jalr	-1208(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059fe:	04c92703          	lw	a4,76(s2)
    80005a02:	02000793          	li	a5,32
    80005a06:	f6e7f9e3          	bgeu	a5,a4,80005978 <sys_unlink+0xaa>
    80005a0a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a0e:	4741                	li	a4,16
    80005a10:	86ce                	mv	a3,s3
    80005a12:	f1840613          	addi	a2,s0,-232
    80005a16:	4581                	li	a1,0
    80005a18:	854a                	mv	a0,s2
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	376080e7          	jalr	886(ra) # 80003d90 <readi>
    80005a22:	47c1                	li	a5,16
    80005a24:	00f51b63          	bne	a0,a5,80005a3a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a28:	f1845783          	lhu	a5,-232(s0)
    80005a2c:	e7a1                	bnez	a5,80005a74 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a2e:	29c1                	addiw	s3,s3,16
    80005a30:	04c92783          	lw	a5,76(s2)
    80005a34:	fcf9ede3          	bltu	s3,a5,80005a0e <sys_unlink+0x140>
    80005a38:	b781                	j	80005978 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a3a:	00003517          	auipc	a0,0x3
    80005a3e:	d0650513          	addi	a0,a0,-762 # 80008740 <syscalls+0x2e0>
    80005a42:	ffffb097          	auipc	ra,0xffffb
    80005a46:	afc080e7          	jalr	-1284(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005a4a:	00003517          	auipc	a0,0x3
    80005a4e:	d0e50513          	addi	a0,a0,-754 # 80008758 <syscalls+0x2f8>
    80005a52:	ffffb097          	auipc	ra,0xffffb
    80005a56:	aec080e7          	jalr	-1300(ra) # 8000053e <panic>
    dp->nlink--;
    80005a5a:	04a4d783          	lhu	a5,74(s1)
    80005a5e:	37fd                	addiw	a5,a5,-1
    80005a60:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a64:	8526                	mv	a0,s1
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	fac080e7          	jalr	-84(ra) # 80003a12 <iupdate>
    80005a6e:	b781                	j	800059ae <sys_unlink+0xe0>
    return -1;
    80005a70:	557d                	li	a0,-1
    80005a72:	a005                	j	80005a92 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a74:	854a                	mv	a0,s2
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	2c8080e7          	jalr	712(ra) # 80003d3e <iunlockput>
  iunlockput(dp);
    80005a7e:	8526                	mv	a0,s1
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	2be080e7          	jalr	702(ra) # 80003d3e <iunlockput>
  end_op();
    80005a88:	fffff097          	auipc	ra,0xfffff
    80005a8c:	a96080e7          	jalr	-1386(ra) # 8000451e <end_op>
  return -1;
    80005a90:	557d                	li	a0,-1
}
    80005a92:	70ae                	ld	ra,232(sp)
    80005a94:	740e                	ld	s0,224(sp)
    80005a96:	64ee                	ld	s1,216(sp)
    80005a98:	694e                	ld	s2,208(sp)
    80005a9a:	69ae                	ld	s3,200(sp)
    80005a9c:	616d                	addi	sp,sp,240
    80005a9e:	8082                	ret

0000000080005aa0 <sys_open>:

uint64
sys_open(void)
{
    80005aa0:	7131                	addi	sp,sp,-192
    80005aa2:	fd06                	sd	ra,184(sp)
    80005aa4:	f922                	sd	s0,176(sp)
    80005aa6:	f526                	sd	s1,168(sp)
    80005aa8:	f14a                	sd	s2,160(sp)
    80005aaa:	ed4e                	sd	s3,152(sp)
    80005aac:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005aae:	f4c40593          	addi	a1,s0,-180
    80005ab2:	4505                	li	a0,1
    80005ab4:	ffffd097          	auipc	ra,0xffffd
    80005ab8:	362080e7          	jalr	866(ra) # 80002e16 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005abc:	08000613          	li	a2,128
    80005ac0:	f5040593          	addi	a1,s0,-176
    80005ac4:	4501                	li	a0,0
    80005ac6:	ffffd097          	auipc	ra,0xffffd
    80005aca:	390080e7          	jalr	912(ra) # 80002e56 <argstr>
    80005ace:	87aa                	mv	a5,a0
    return -1;
    80005ad0:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ad2:	0a07c963          	bltz	a5,80005b84 <sys_open+0xe4>

  begin_op();
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	9c8080e7          	jalr	-1592(ra) # 8000449e <begin_op>

  if(omode & O_CREATE){
    80005ade:	f4c42783          	lw	a5,-180(s0)
    80005ae2:	2007f793          	andi	a5,a5,512
    80005ae6:	cfc5                	beqz	a5,80005b9e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ae8:	4681                	li	a3,0
    80005aea:	4601                	li	a2,0
    80005aec:	4589                	li	a1,2
    80005aee:	f5040513          	addi	a0,s0,-176
    80005af2:	00000097          	auipc	ra,0x0
    80005af6:	954080e7          	jalr	-1708(ra) # 80005446 <create>
    80005afa:	84aa                	mv	s1,a0
    if(ip == 0){
    80005afc:	c959                	beqz	a0,80005b92 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005afe:	04449703          	lh	a4,68(s1)
    80005b02:	478d                	li	a5,3
    80005b04:	00f71763          	bne	a4,a5,80005b12 <sys_open+0x72>
    80005b08:	0464d703          	lhu	a4,70(s1)
    80005b0c:	47a5                	li	a5,9
    80005b0e:	0ce7ed63          	bltu	a5,a4,80005be8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	d9c080e7          	jalr	-612(ra) # 800048ae <filealloc>
    80005b1a:	89aa                	mv	s3,a0
    80005b1c:	10050363          	beqz	a0,80005c22 <sys_open+0x182>
    80005b20:	00000097          	auipc	ra,0x0
    80005b24:	8e4080e7          	jalr	-1820(ra) # 80005404 <fdalloc>
    80005b28:	892a                	mv	s2,a0
    80005b2a:	0e054763          	bltz	a0,80005c18 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b2e:	04449703          	lh	a4,68(s1)
    80005b32:	478d                	li	a5,3
    80005b34:	0cf70563          	beq	a4,a5,80005bfe <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b38:	4789                	li	a5,2
    80005b3a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b3e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b42:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b46:	f4c42783          	lw	a5,-180(s0)
    80005b4a:	0017c713          	xori	a4,a5,1
    80005b4e:	8b05                	andi	a4,a4,1
    80005b50:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b54:	0037f713          	andi	a4,a5,3
    80005b58:	00e03733          	snez	a4,a4
    80005b5c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b60:	4007f793          	andi	a5,a5,1024
    80005b64:	c791                	beqz	a5,80005b70 <sys_open+0xd0>
    80005b66:	04449703          	lh	a4,68(s1)
    80005b6a:	4789                	li	a5,2
    80005b6c:	0af70063          	beq	a4,a5,80005c0c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b70:	8526                	mv	a0,s1
    80005b72:	ffffe097          	auipc	ra,0xffffe
    80005b76:	02c080e7          	jalr	44(ra) # 80003b9e <iunlock>
  end_op();
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	9a4080e7          	jalr	-1628(ra) # 8000451e <end_op>

  return fd;
    80005b82:	854a                	mv	a0,s2
}
    80005b84:	70ea                	ld	ra,184(sp)
    80005b86:	744a                	ld	s0,176(sp)
    80005b88:	74aa                	ld	s1,168(sp)
    80005b8a:	790a                	ld	s2,160(sp)
    80005b8c:	69ea                	ld	s3,152(sp)
    80005b8e:	6129                	addi	sp,sp,192
    80005b90:	8082                	ret
      end_op();
    80005b92:	fffff097          	auipc	ra,0xfffff
    80005b96:	98c080e7          	jalr	-1652(ra) # 8000451e <end_op>
      return -1;
    80005b9a:	557d                	li	a0,-1
    80005b9c:	b7e5                	j	80005b84 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b9e:	f5040513          	addi	a0,s0,-176
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	6e0080e7          	jalr	1760(ra) # 80004282 <namei>
    80005baa:	84aa                	mv	s1,a0
    80005bac:	c905                	beqz	a0,80005bdc <sys_open+0x13c>
    ilock(ip);
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	f2e080e7          	jalr	-210(ra) # 80003adc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bb6:	04449703          	lh	a4,68(s1)
    80005bba:	4785                	li	a5,1
    80005bbc:	f4f711e3          	bne	a4,a5,80005afe <sys_open+0x5e>
    80005bc0:	f4c42783          	lw	a5,-180(s0)
    80005bc4:	d7b9                	beqz	a5,80005b12 <sys_open+0x72>
      iunlockput(ip);
    80005bc6:	8526                	mv	a0,s1
    80005bc8:	ffffe097          	auipc	ra,0xffffe
    80005bcc:	176080e7          	jalr	374(ra) # 80003d3e <iunlockput>
      end_op();
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	94e080e7          	jalr	-1714(ra) # 8000451e <end_op>
      return -1;
    80005bd8:	557d                	li	a0,-1
    80005bda:	b76d                	j	80005b84 <sys_open+0xe4>
      end_op();
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	942080e7          	jalr	-1726(ra) # 8000451e <end_op>
      return -1;
    80005be4:	557d                	li	a0,-1
    80005be6:	bf79                	j	80005b84 <sys_open+0xe4>
    iunlockput(ip);
    80005be8:	8526                	mv	a0,s1
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	154080e7          	jalr	340(ra) # 80003d3e <iunlockput>
    end_op();
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	92c080e7          	jalr	-1748(ra) # 8000451e <end_op>
    return -1;
    80005bfa:	557d                	li	a0,-1
    80005bfc:	b761                	j	80005b84 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005bfe:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c02:	04649783          	lh	a5,70(s1)
    80005c06:	02f99223          	sh	a5,36(s3)
    80005c0a:	bf25                	j	80005b42 <sys_open+0xa2>
    itrunc(ip);
    80005c0c:	8526                	mv	a0,s1
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	fdc080e7          	jalr	-36(ra) # 80003bea <itrunc>
    80005c16:	bfa9                	j	80005b70 <sys_open+0xd0>
      fileclose(f);
    80005c18:	854e                	mv	a0,s3
    80005c1a:	fffff097          	auipc	ra,0xfffff
    80005c1e:	d50080e7          	jalr	-688(ra) # 8000496a <fileclose>
    iunlockput(ip);
    80005c22:	8526                	mv	a0,s1
    80005c24:	ffffe097          	auipc	ra,0xffffe
    80005c28:	11a080e7          	jalr	282(ra) # 80003d3e <iunlockput>
    end_op();
    80005c2c:	fffff097          	auipc	ra,0xfffff
    80005c30:	8f2080e7          	jalr	-1806(ra) # 8000451e <end_op>
    return -1;
    80005c34:	557d                	li	a0,-1
    80005c36:	b7b9                	j	80005b84 <sys_open+0xe4>

0000000080005c38 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c38:	7175                	addi	sp,sp,-144
    80005c3a:	e506                	sd	ra,136(sp)
    80005c3c:	e122                	sd	s0,128(sp)
    80005c3e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	85e080e7          	jalr	-1954(ra) # 8000449e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c48:	08000613          	li	a2,128
    80005c4c:	f7040593          	addi	a1,s0,-144
    80005c50:	4501                	li	a0,0
    80005c52:	ffffd097          	auipc	ra,0xffffd
    80005c56:	204080e7          	jalr	516(ra) # 80002e56 <argstr>
    80005c5a:	02054963          	bltz	a0,80005c8c <sys_mkdir+0x54>
    80005c5e:	4681                	li	a3,0
    80005c60:	4601                	li	a2,0
    80005c62:	4585                	li	a1,1
    80005c64:	f7040513          	addi	a0,s0,-144
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	7de080e7          	jalr	2014(ra) # 80005446 <create>
    80005c70:	cd11                	beqz	a0,80005c8c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	0cc080e7          	jalr	204(ra) # 80003d3e <iunlockput>
  end_op();
    80005c7a:	fffff097          	auipc	ra,0xfffff
    80005c7e:	8a4080e7          	jalr	-1884(ra) # 8000451e <end_op>
  return 0;
    80005c82:	4501                	li	a0,0
}
    80005c84:	60aa                	ld	ra,136(sp)
    80005c86:	640a                	ld	s0,128(sp)
    80005c88:	6149                	addi	sp,sp,144
    80005c8a:	8082                	ret
    end_op();
    80005c8c:	fffff097          	auipc	ra,0xfffff
    80005c90:	892080e7          	jalr	-1902(ra) # 8000451e <end_op>
    return -1;
    80005c94:	557d                	li	a0,-1
    80005c96:	b7fd                	j	80005c84 <sys_mkdir+0x4c>

0000000080005c98 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c98:	7135                	addi	sp,sp,-160
    80005c9a:	ed06                	sd	ra,152(sp)
    80005c9c:	e922                	sd	s0,144(sp)
    80005c9e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	7fe080e7          	jalr	2046(ra) # 8000449e <begin_op>
  argint(1, &major);
    80005ca8:	f6c40593          	addi	a1,s0,-148
    80005cac:	4505                	li	a0,1
    80005cae:	ffffd097          	auipc	ra,0xffffd
    80005cb2:	168080e7          	jalr	360(ra) # 80002e16 <argint>
  argint(2, &minor);
    80005cb6:	f6840593          	addi	a1,s0,-152
    80005cba:	4509                	li	a0,2
    80005cbc:	ffffd097          	auipc	ra,0xffffd
    80005cc0:	15a080e7          	jalr	346(ra) # 80002e16 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cc4:	08000613          	li	a2,128
    80005cc8:	f7040593          	addi	a1,s0,-144
    80005ccc:	4501                	li	a0,0
    80005cce:	ffffd097          	auipc	ra,0xffffd
    80005cd2:	188080e7          	jalr	392(ra) # 80002e56 <argstr>
    80005cd6:	02054b63          	bltz	a0,80005d0c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005cda:	f6841683          	lh	a3,-152(s0)
    80005cde:	f6c41603          	lh	a2,-148(s0)
    80005ce2:	458d                	li	a1,3
    80005ce4:	f7040513          	addi	a0,s0,-144
    80005ce8:	fffff097          	auipc	ra,0xfffff
    80005cec:	75e080e7          	jalr	1886(ra) # 80005446 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cf0:	cd11                	beqz	a0,80005d0c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cf2:	ffffe097          	auipc	ra,0xffffe
    80005cf6:	04c080e7          	jalr	76(ra) # 80003d3e <iunlockput>
  end_op();
    80005cfa:	fffff097          	auipc	ra,0xfffff
    80005cfe:	824080e7          	jalr	-2012(ra) # 8000451e <end_op>
  return 0;
    80005d02:	4501                	li	a0,0
}
    80005d04:	60ea                	ld	ra,152(sp)
    80005d06:	644a                	ld	s0,144(sp)
    80005d08:	610d                	addi	sp,sp,160
    80005d0a:	8082                	ret
    end_op();
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	812080e7          	jalr	-2030(ra) # 8000451e <end_op>
    return -1;
    80005d14:	557d                	li	a0,-1
    80005d16:	b7fd                	j	80005d04 <sys_mknod+0x6c>

0000000080005d18 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d18:	7135                	addi	sp,sp,-160
    80005d1a:	ed06                	sd	ra,152(sp)
    80005d1c:	e922                	sd	s0,144(sp)
    80005d1e:	e526                	sd	s1,136(sp)
    80005d20:	e14a                	sd	s2,128(sp)
    80005d22:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d24:	ffffc097          	auipc	ra,0xffffc
    80005d28:	c88080e7          	jalr	-888(ra) # 800019ac <myproc>
    80005d2c:	892a                	mv	s2,a0
  
  begin_op();
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	770080e7          	jalr	1904(ra) # 8000449e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d36:	08000613          	li	a2,128
    80005d3a:	f6040593          	addi	a1,s0,-160
    80005d3e:	4501                	li	a0,0
    80005d40:	ffffd097          	auipc	ra,0xffffd
    80005d44:	116080e7          	jalr	278(ra) # 80002e56 <argstr>
    80005d48:	04054b63          	bltz	a0,80005d9e <sys_chdir+0x86>
    80005d4c:	f6040513          	addi	a0,s0,-160
    80005d50:	ffffe097          	auipc	ra,0xffffe
    80005d54:	532080e7          	jalr	1330(ra) # 80004282 <namei>
    80005d58:	84aa                	mv	s1,a0
    80005d5a:	c131                	beqz	a0,80005d9e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d5c:	ffffe097          	auipc	ra,0xffffe
    80005d60:	d80080e7          	jalr	-640(ra) # 80003adc <ilock>
  if(ip->type != T_DIR){
    80005d64:	04449703          	lh	a4,68(s1)
    80005d68:	4785                	li	a5,1
    80005d6a:	04f71063          	bne	a4,a5,80005daa <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d6e:	8526                	mv	a0,s1
    80005d70:	ffffe097          	auipc	ra,0xffffe
    80005d74:	e2e080e7          	jalr	-466(ra) # 80003b9e <iunlock>
  iput(p->cwd);
    80005d78:	15093503          	ld	a0,336(s2)
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	f1a080e7          	jalr	-230(ra) # 80003c96 <iput>
  end_op();
    80005d84:	ffffe097          	auipc	ra,0xffffe
    80005d88:	79a080e7          	jalr	1946(ra) # 8000451e <end_op>
  p->cwd = ip;
    80005d8c:	14993823          	sd	s1,336(s2)
  return 0;
    80005d90:	4501                	li	a0,0
}
    80005d92:	60ea                	ld	ra,152(sp)
    80005d94:	644a                	ld	s0,144(sp)
    80005d96:	64aa                	ld	s1,136(sp)
    80005d98:	690a                	ld	s2,128(sp)
    80005d9a:	610d                	addi	sp,sp,160
    80005d9c:	8082                	ret
    end_op();
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	780080e7          	jalr	1920(ra) # 8000451e <end_op>
    return -1;
    80005da6:	557d                	li	a0,-1
    80005da8:	b7ed                	j	80005d92 <sys_chdir+0x7a>
    iunlockput(ip);
    80005daa:	8526                	mv	a0,s1
    80005dac:	ffffe097          	auipc	ra,0xffffe
    80005db0:	f92080e7          	jalr	-110(ra) # 80003d3e <iunlockput>
    end_op();
    80005db4:	ffffe097          	auipc	ra,0xffffe
    80005db8:	76a080e7          	jalr	1898(ra) # 8000451e <end_op>
    return -1;
    80005dbc:	557d                	li	a0,-1
    80005dbe:	bfd1                	j	80005d92 <sys_chdir+0x7a>

0000000080005dc0 <sys_exec>:

uint64
sys_exec(void)
{
    80005dc0:	7145                	addi	sp,sp,-464
    80005dc2:	e786                	sd	ra,456(sp)
    80005dc4:	e3a2                	sd	s0,448(sp)
    80005dc6:	ff26                	sd	s1,440(sp)
    80005dc8:	fb4a                	sd	s2,432(sp)
    80005dca:	f74e                	sd	s3,424(sp)
    80005dcc:	f352                	sd	s4,416(sp)
    80005dce:	ef56                	sd	s5,408(sp)
    80005dd0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005dd2:	e3840593          	addi	a1,s0,-456
    80005dd6:	4505                	li	a0,1
    80005dd8:	ffffd097          	auipc	ra,0xffffd
    80005ddc:	05e080e7          	jalr	94(ra) # 80002e36 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005de0:	08000613          	li	a2,128
    80005de4:	f4040593          	addi	a1,s0,-192
    80005de8:	4501                	li	a0,0
    80005dea:	ffffd097          	auipc	ra,0xffffd
    80005dee:	06c080e7          	jalr	108(ra) # 80002e56 <argstr>
    80005df2:	87aa                	mv	a5,a0
    return -1;
    80005df4:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005df6:	0c07c263          	bltz	a5,80005eba <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005dfa:	10000613          	li	a2,256
    80005dfe:	4581                	li	a1,0
    80005e00:	e4040513          	addi	a0,s0,-448
    80005e04:	ffffb097          	auipc	ra,0xffffb
    80005e08:	ece080e7          	jalr	-306(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e0c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e10:	89a6                	mv	s3,s1
    80005e12:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e14:	02000a13          	li	s4,32
    80005e18:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e1c:	00391793          	slli	a5,s2,0x3
    80005e20:	e3040593          	addi	a1,s0,-464
    80005e24:	e3843503          	ld	a0,-456(s0)
    80005e28:	953e                	add	a0,a0,a5
    80005e2a:	ffffd097          	auipc	ra,0xffffd
    80005e2e:	f4e080e7          	jalr	-178(ra) # 80002d78 <fetchaddr>
    80005e32:	02054a63          	bltz	a0,80005e66 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005e36:	e3043783          	ld	a5,-464(s0)
    80005e3a:	c3b9                	beqz	a5,80005e80 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e3c:	ffffb097          	auipc	ra,0xffffb
    80005e40:	caa080e7          	jalr	-854(ra) # 80000ae6 <kalloc>
    80005e44:	85aa                	mv	a1,a0
    80005e46:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e4a:	cd11                	beqz	a0,80005e66 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e4c:	6605                	lui	a2,0x1
    80005e4e:	e3043503          	ld	a0,-464(s0)
    80005e52:	ffffd097          	auipc	ra,0xffffd
    80005e56:	f78080e7          	jalr	-136(ra) # 80002dca <fetchstr>
    80005e5a:	00054663          	bltz	a0,80005e66 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005e5e:	0905                	addi	s2,s2,1
    80005e60:	09a1                	addi	s3,s3,8
    80005e62:	fb491be3          	bne	s2,s4,80005e18 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e66:	10048913          	addi	s2,s1,256
    80005e6a:	6088                	ld	a0,0(s1)
    80005e6c:	c531                	beqz	a0,80005eb8 <sys_exec+0xf8>
    kfree(argv[i]);
    80005e6e:	ffffb097          	auipc	ra,0xffffb
    80005e72:	b7c080e7          	jalr	-1156(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e76:	04a1                	addi	s1,s1,8
    80005e78:	ff2499e3          	bne	s1,s2,80005e6a <sys_exec+0xaa>
  return -1;
    80005e7c:	557d                	li	a0,-1
    80005e7e:	a835                	j	80005eba <sys_exec+0xfa>
      argv[i] = 0;
    80005e80:	0a8e                	slli	s5,s5,0x3
    80005e82:	fc040793          	addi	a5,s0,-64
    80005e86:	9abe                	add	s5,s5,a5
    80005e88:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e8c:	e4040593          	addi	a1,s0,-448
    80005e90:	f4040513          	addi	a0,s0,-192
    80005e94:	fffff097          	auipc	ra,0xfffff
    80005e98:	150080e7          	jalr	336(ra) # 80004fe4 <exec>
    80005e9c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e9e:	10048993          	addi	s3,s1,256
    80005ea2:	6088                	ld	a0,0(s1)
    80005ea4:	c901                	beqz	a0,80005eb4 <sys_exec+0xf4>
    kfree(argv[i]);
    80005ea6:	ffffb097          	auipc	ra,0xffffb
    80005eaa:	b44080e7          	jalr	-1212(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eae:	04a1                	addi	s1,s1,8
    80005eb0:	ff3499e3          	bne	s1,s3,80005ea2 <sys_exec+0xe2>
  return ret;
    80005eb4:	854a                	mv	a0,s2
    80005eb6:	a011                	j	80005eba <sys_exec+0xfa>
  return -1;
    80005eb8:	557d                	li	a0,-1
}
    80005eba:	60be                	ld	ra,456(sp)
    80005ebc:	641e                	ld	s0,448(sp)
    80005ebe:	74fa                	ld	s1,440(sp)
    80005ec0:	795a                	ld	s2,432(sp)
    80005ec2:	79ba                	ld	s3,424(sp)
    80005ec4:	7a1a                	ld	s4,416(sp)
    80005ec6:	6afa                	ld	s5,408(sp)
    80005ec8:	6179                	addi	sp,sp,464
    80005eca:	8082                	ret

0000000080005ecc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ecc:	7139                	addi	sp,sp,-64
    80005ece:	fc06                	sd	ra,56(sp)
    80005ed0:	f822                	sd	s0,48(sp)
    80005ed2:	f426                	sd	s1,40(sp)
    80005ed4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ed6:	ffffc097          	auipc	ra,0xffffc
    80005eda:	ad6080e7          	jalr	-1322(ra) # 800019ac <myproc>
    80005ede:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005ee0:	fd840593          	addi	a1,s0,-40
    80005ee4:	4501                	li	a0,0
    80005ee6:	ffffd097          	auipc	ra,0xffffd
    80005eea:	f50080e7          	jalr	-176(ra) # 80002e36 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005eee:	fc840593          	addi	a1,s0,-56
    80005ef2:	fd040513          	addi	a0,s0,-48
    80005ef6:	fffff097          	auipc	ra,0xfffff
    80005efa:	da4080e7          	jalr	-604(ra) # 80004c9a <pipealloc>
    return -1;
    80005efe:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f00:	0c054463          	bltz	a0,80005fc8 <sys_pipe+0xfc>
  fd0 = -1;
    80005f04:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f08:	fd043503          	ld	a0,-48(s0)
    80005f0c:	fffff097          	auipc	ra,0xfffff
    80005f10:	4f8080e7          	jalr	1272(ra) # 80005404 <fdalloc>
    80005f14:	fca42223          	sw	a0,-60(s0)
    80005f18:	08054b63          	bltz	a0,80005fae <sys_pipe+0xe2>
    80005f1c:	fc843503          	ld	a0,-56(s0)
    80005f20:	fffff097          	auipc	ra,0xfffff
    80005f24:	4e4080e7          	jalr	1252(ra) # 80005404 <fdalloc>
    80005f28:	fca42023          	sw	a0,-64(s0)
    80005f2c:	06054863          	bltz	a0,80005f9c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f30:	4691                	li	a3,4
    80005f32:	fc440613          	addi	a2,s0,-60
    80005f36:	fd843583          	ld	a1,-40(s0)
    80005f3a:	68a8                	ld	a0,80(s1)
    80005f3c:	ffffb097          	auipc	ra,0xffffb
    80005f40:	72c080e7          	jalr	1836(ra) # 80001668 <copyout>
    80005f44:	02054063          	bltz	a0,80005f64 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f48:	4691                	li	a3,4
    80005f4a:	fc040613          	addi	a2,s0,-64
    80005f4e:	fd843583          	ld	a1,-40(s0)
    80005f52:	0591                	addi	a1,a1,4
    80005f54:	68a8                	ld	a0,80(s1)
    80005f56:	ffffb097          	auipc	ra,0xffffb
    80005f5a:	712080e7          	jalr	1810(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f5e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f60:	06055463          	bgez	a0,80005fc8 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005f64:	fc442783          	lw	a5,-60(s0)
    80005f68:	07e9                	addi	a5,a5,26
    80005f6a:	078e                	slli	a5,a5,0x3
    80005f6c:	97a6                	add	a5,a5,s1
    80005f6e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f72:	fc042503          	lw	a0,-64(s0)
    80005f76:	0569                	addi	a0,a0,26
    80005f78:	050e                	slli	a0,a0,0x3
    80005f7a:	94aa                	add	s1,s1,a0
    80005f7c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005f80:	fd043503          	ld	a0,-48(s0)
    80005f84:	fffff097          	auipc	ra,0xfffff
    80005f88:	9e6080e7          	jalr	-1562(ra) # 8000496a <fileclose>
    fileclose(wf);
    80005f8c:	fc843503          	ld	a0,-56(s0)
    80005f90:	fffff097          	auipc	ra,0xfffff
    80005f94:	9da080e7          	jalr	-1574(ra) # 8000496a <fileclose>
    return -1;
    80005f98:	57fd                	li	a5,-1
    80005f9a:	a03d                	j	80005fc8 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005f9c:	fc442783          	lw	a5,-60(s0)
    80005fa0:	0007c763          	bltz	a5,80005fae <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005fa4:	07e9                	addi	a5,a5,26
    80005fa6:	078e                	slli	a5,a5,0x3
    80005fa8:	94be                	add	s1,s1,a5
    80005faa:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005fae:	fd043503          	ld	a0,-48(s0)
    80005fb2:	fffff097          	auipc	ra,0xfffff
    80005fb6:	9b8080e7          	jalr	-1608(ra) # 8000496a <fileclose>
    fileclose(wf);
    80005fba:	fc843503          	ld	a0,-56(s0)
    80005fbe:	fffff097          	auipc	ra,0xfffff
    80005fc2:	9ac080e7          	jalr	-1620(ra) # 8000496a <fileclose>
    return -1;
    80005fc6:	57fd                	li	a5,-1
}
    80005fc8:	853e                	mv	a0,a5
    80005fca:	70e2                	ld	ra,56(sp)
    80005fcc:	7442                	ld	s0,48(sp)
    80005fce:	74a2                	ld	s1,40(sp)
    80005fd0:	6121                	addi	sp,sp,64
    80005fd2:	8082                	ret
	...

0000000080005fe0 <kernelvec>:
    80005fe0:	7111                	addi	sp,sp,-256
    80005fe2:	e006                	sd	ra,0(sp)
    80005fe4:	e40a                	sd	sp,8(sp)
    80005fe6:	e80e                	sd	gp,16(sp)
    80005fe8:	ec12                	sd	tp,24(sp)
    80005fea:	f016                	sd	t0,32(sp)
    80005fec:	f41a                	sd	t1,40(sp)
    80005fee:	f81e                	sd	t2,48(sp)
    80005ff0:	fc22                	sd	s0,56(sp)
    80005ff2:	e0a6                	sd	s1,64(sp)
    80005ff4:	e4aa                	sd	a0,72(sp)
    80005ff6:	e8ae                	sd	a1,80(sp)
    80005ff8:	ecb2                	sd	a2,88(sp)
    80005ffa:	f0b6                	sd	a3,96(sp)
    80005ffc:	f4ba                	sd	a4,104(sp)
    80005ffe:	f8be                	sd	a5,112(sp)
    80006000:	fcc2                	sd	a6,120(sp)
    80006002:	e146                	sd	a7,128(sp)
    80006004:	e54a                	sd	s2,136(sp)
    80006006:	e94e                	sd	s3,144(sp)
    80006008:	ed52                	sd	s4,152(sp)
    8000600a:	f156                	sd	s5,160(sp)
    8000600c:	f55a                	sd	s6,168(sp)
    8000600e:	f95e                	sd	s7,176(sp)
    80006010:	fd62                	sd	s8,184(sp)
    80006012:	e1e6                	sd	s9,192(sp)
    80006014:	e5ea                	sd	s10,200(sp)
    80006016:	e9ee                	sd	s11,208(sp)
    80006018:	edf2                	sd	t3,216(sp)
    8000601a:	f1f6                	sd	t4,224(sp)
    8000601c:	f5fa                	sd	t5,232(sp)
    8000601e:	f9fe                	sd	t6,240(sp)
    80006020:	c25fc0ef          	jal	ra,80002c44 <kerneltrap>
    80006024:	6082                	ld	ra,0(sp)
    80006026:	6122                	ld	sp,8(sp)
    80006028:	61c2                	ld	gp,16(sp)
    8000602a:	7282                	ld	t0,32(sp)
    8000602c:	7322                	ld	t1,40(sp)
    8000602e:	73c2                	ld	t2,48(sp)
    80006030:	7462                	ld	s0,56(sp)
    80006032:	6486                	ld	s1,64(sp)
    80006034:	6526                	ld	a0,72(sp)
    80006036:	65c6                	ld	a1,80(sp)
    80006038:	6666                	ld	a2,88(sp)
    8000603a:	7686                	ld	a3,96(sp)
    8000603c:	7726                	ld	a4,104(sp)
    8000603e:	77c6                	ld	a5,112(sp)
    80006040:	7866                	ld	a6,120(sp)
    80006042:	688a                	ld	a7,128(sp)
    80006044:	692a                	ld	s2,136(sp)
    80006046:	69ca                	ld	s3,144(sp)
    80006048:	6a6a                	ld	s4,152(sp)
    8000604a:	7a8a                	ld	s5,160(sp)
    8000604c:	7b2a                	ld	s6,168(sp)
    8000604e:	7bca                	ld	s7,176(sp)
    80006050:	7c6a                	ld	s8,184(sp)
    80006052:	6c8e                	ld	s9,192(sp)
    80006054:	6d2e                	ld	s10,200(sp)
    80006056:	6dce                	ld	s11,208(sp)
    80006058:	6e6e                	ld	t3,216(sp)
    8000605a:	7e8e                	ld	t4,224(sp)
    8000605c:	7f2e                	ld	t5,232(sp)
    8000605e:	7fce                	ld	t6,240(sp)
    80006060:	6111                	addi	sp,sp,256
    80006062:	10200073          	sret
    80006066:	00000013          	nop
    8000606a:	00000013          	nop
    8000606e:	0001                	nop

0000000080006070 <timervec>:
    80006070:	34051573          	csrrw	a0,mscratch,a0
    80006074:	e10c                	sd	a1,0(a0)
    80006076:	e510                	sd	a2,8(a0)
    80006078:	e914                	sd	a3,16(a0)
    8000607a:	6d0c                	ld	a1,24(a0)
    8000607c:	7110                	ld	a2,32(a0)
    8000607e:	6194                	ld	a3,0(a1)
    80006080:	96b2                	add	a3,a3,a2
    80006082:	e194                	sd	a3,0(a1)
    80006084:	4589                	li	a1,2
    80006086:	14459073          	csrw	sip,a1
    8000608a:	6914                	ld	a3,16(a0)
    8000608c:	6510                	ld	a2,8(a0)
    8000608e:	610c                	ld	a1,0(a0)
    80006090:	34051573          	csrrw	a0,mscratch,a0
    80006094:	30200073          	mret
	...

000000008000609a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000609a:	1141                	addi	sp,sp,-16
    8000609c:	e422                	sd	s0,8(sp)
    8000609e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060a0:	0c0007b7          	lui	a5,0xc000
    800060a4:	4705                	li	a4,1
    800060a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060a8:	c3d8                	sw	a4,4(a5)
}
    800060aa:	6422                	ld	s0,8(sp)
    800060ac:	0141                	addi	sp,sp,16
    800060ae:	8082                	ret

00000000800060b0 <plicinithart>:

void
plicinithart(void)
{
    800060b0:	1141                	addi	sp,sp,-16
    800060b2:	e406                	sd	ra,8(sp)
    800060b4:	e022                	sd	s0,0(sp)
    800060b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060b8:	ffffc097          	auipc	ra,0xffffc
    800060bc:	8c8080e7          	jalr	-1848(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060c0:	0085171b          	slliw	a4,a0,0x8
    800060c4:	0c0027b7          	lui	a5,0xc002
    800060c8:	97ba                	add	a5,a5,a4
    800060ca:	40200713          	li	a4,1026
    800060ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060d2:	00d5151b          	slliw	a0,a0,0xd
    800060d6:	0c2017b7          	lui	a5,0xc201
    800060da:	953e                	add	a0,a0,a5
    800060dc:	00052023          	sw	zero,0(a0)
}
    800060e0:	60a2                	ld	ra,8(sp)
    800060e2:	6402                	ld	s0,0(sp)
    800060e4:	0141                	addi	sp,sp,16
    800060e6:	8082                	ret

00000000800060e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060e8:	1141                	addi	sp,sp,-16
    800060ea:	e406                	sd	ra,8(sp)
    800060ec:	e022                	sd	s0,0(sp)
    800060ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060f0:	ffffc097          	auipc	ra,0xffffc
    800060f4:	890080e7          	jalr	-1904(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060f8:	00d5179b          	slliw	a5,a0,0xd
    800060fc:	0c201537          	lui	a0,0xc201
    80006100:	953e                	add	a0,a0,a5
  return irq;
}
    80006102:	4148                	lw	a0,4(a0)
    80006104:	60a2                	ld	ra,8(sp)
    80006106:	6402                	ld	s0,0(sp)
    80006108:	0141                	addi	sp,sp,16
    8000610a:	8082                	ret

000000008000610c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000610c:	1101                	addi	sp,sp,-32
    8000610e:	ec06                	sd	ra,24(sp)
    80006110:	e822                	sd	s0,16(sp)
    80006112:	e426                	sd	s1,8(sp)
    80006114:	1000                	addi	s0,sp,32
    80006116:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006118:	ffffc097          	auipc	ra,0xffffc
    8000611c:	868080e7          	jalr	-1944(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006120:	00d5151b          	slliw	a0,a0,0xd
    80006124:	0c2017b7          	lui	a5,0xc201
    80006128:	97aa                	add	a5,a5,a0
    8000612a:	c3c4                	sw	s1,4(a5)
}
    8000612c:	60e2                	ld	ra,24(sp)
    8000612e:	6442                	ld	s0,16(sp)
    80006130:	64a2                	ld	s1,8(sp)
    80006132:	6105                	addi	sp,sp,32
    80006134:	8082                	ret

0000000080006136 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006136:	1141                	addi	sp,sp,-16
    80006138:	e406                	sd	ra,8(sp)
    8000613a:	e022                	sd	s0,0(sp)
    8000613c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000613e:	479d                	li	a5,7
    80006140:	04a7cc63          	blt	a5,a0,80006198 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006144:	0001c797          	auipc	a5,0x1c
    80006148:	4ec78793          	addi	a5,a5,1260 # 80022630 <disk>
    8000614c:	97aa                	add	a5,a5,a0
    8000614e:	0187c783          	lbu	a5,24(a5)
    80006152:	ebb9                	bnez	a5,800061a8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006154:	00451613          	slli	a2,a0,0x4
    80006158:	0001c797          	auipc	a5,0x1c
    8000615c:	4d878793          	addi	a5,a5,1240 # 80022630 <disk>
    80006160:	6394                	ld	a3,0(a5)
    80006162:	96b2                	add	a3,a3,a2
    80006164:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006168:	6398                	ld	a4,0(a5)
    8000616a:	9732                	add	a4,a4,a2
    8000616c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006170:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006174:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006178:	953e                	add	a0,a0,a5
    8000617a:	4785                	li	a5,1
    8000617c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006180:	0001c517          	auipc	a0,0x1c
    80006184:	4c850513          	addi	a0,a0,1224 # 80022648 <disk+0x18>
    80006188:	ffffc097          	auipc	ra,0xffffc
    8000618c:	05c080e7          	jalr	92(ra) # 800021e4 <wakeup>
}
    80006190:	60a2                	ld	ra,8(sp)
    80006192:	6402                	ld	s0,0(sp)
    80006194:	0141                	addi	sp,sp,16
    80006196:	8082                	ret
    panic("free_desc 1");
    80006198:	00002517          	auipc	a0,0x2
    8000619c:	5d050513          	addi	a0,a0,1488 # 80008768 <syscalls+0x308>
    800061a0:	ffffa097          	auipc	ra,0xffffa
    800061a4:	39e080e7          	jalr	926(ra) # 8000053e <panic>
    panic("free_desc 2");
    800061a8:	00002517          	auipc	a0,0x2
    800061ac:	5d050513          	addi	a0,a0,1488 # 80008778 <syscalls+0x318>
    800061b0:	ffffa097          	auipc	ra,0xffffa
    800061b4:	38e080e7          	jalr	910(ra) # 8000053e <panic>

00000000800061b8 <virtio_disk_init>:
{
    800061b8:	1101                	addi	sp,sp,-32
    800061ba:	ec06                	sd	ra,24(sp)
    800061bc:	e822                	sd	s0,16(sp)
    800061be:	e426                	sd	s1,8(sp)
    800061c0:	e04a                	sd	s2,0(sp)
    800061c2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061c4:	00002597          	auipc	a1,0x2
    800061c8:	5c458593          	addi	a1,a1,1476 # 80008788 <syscalls+0x328>
    800061cc:	0001c517          	auipc	a0,0x1c
    800061d0:	58c50513          	addi	a0,a0,1420 # 80022758 <disk+0x128>
    800061d4:	ffffb097          	auipc	ra,0xffffb
    800061d8:	972080e7          	jalr	-1678(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061dc:	100017b7          	lui	a5,0x10001
    800061e0:	4398                	lw	a4,0(a5)
    800061e2:	2701                	sext.w	a4,a4
    800061e4:	747277b7          	lui	a5,0x74727
    800061e8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061ec:	14f71c63          	bne	a4,a5,80006344 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800061f0:	100017b7          	lui	a5,0x10001
    800061f4:	43dc                	lw	a5,4(a5)
    800061f6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061f8:	4709                	li	a4,2
    800061fa:	14e79563          	bne	a5,a4,80006344 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061fe:	100017b7          	lui	a5,0x10001
    80006202:	479c                	lw	a5,8(a5)
    80006204:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006206:	12e79f63          	bne	a5,a4,80006344 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000620a:	100017b7          	lui	a5,0x10001
    8000620e:	47d8                	lw	a4,12(a5)
    80006210:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006212:	554d47b7          	lui	a5,0x554d4
    80006216:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000621a:	12f71563          	bne	a4,a5,80006344 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000621e:	100017b7          	lui	a5,0x10001
    80006222:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006226:	4705                	li	a4,1
    80006228:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000622a:	470d                	li	a4,3
    8000622c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000622e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006230:	c7ffe737          	lui	a4,0xc7ffe
    80006234:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbfef>
    80006238:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000623a:	2701                	sext.w	a4,a4
    8000623c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000623e:	472d                	li	a4,11
    80006240:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006242:	5bbc                	lw	a5,112(a5)
    80006244:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006248:	8ba1                	andi	a5,a5,8
    8000624a:	10078563          	beqz	a5,80006354 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000624e:	100017b7          	lui	a5,0x10001
    80006252:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006256:	43fc                	lw	a5,68(a5)
    80006258:	2781                	sext.w	a5,a5
    8000625a:	10079563          	bnez	a5,80006364 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000625e:	100017b7          	lui	a5,0x10001
    80006262:	5bdc                	lw	a5,52(a5)
    80006264:	2781                	sext.w	a5,a5
  if(max == 0)
    80006266:	10078763          	beqz	a5,80006374 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000626a:	471d                	li	a4,7
    8000626c:	10f77c63          	bgeu	a4,a5,80006384 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006270:	ffffb097          	auipc	ra,0xffffb
    80006274:	876080e7          	jalr	-1930(ra) # 80000ae6 <kalloc>
    80006278:	0001c497          	auipc	s1,0x1c
    8000627c:	3b848493          	addi	s1,s1,952 # 80022630 <disk>
    80006280:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006282:	ffffb097          	auipc	ra,0xffffb
    80006286:	864080e7          	jalr	-1948(ra) # 80000ae6 <kalloc>
    8000628a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000628c:	ffffb097          	auipc	ra,0xffffb
    80006290:	85a080e7          	jalr	-1958(ra) # 80000ae6 <kalloc>
    80006294:	87aa                	mv	a5,a0
    80006296:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006298:	6088                	ld	a0,0(s1)
    8000629a:	cd6d                	beqz	a0,80006394 <virtio_disk_init+0x1dc>
    8000629c:	0001c717          	auipc	a4,0x1c
    800062a0:	39c73703          	ld	a4,924(a4) # 80022638 <disk+0x8>
    800062a4:	cb65                	beqz	a4,80006394 <virtio_disk_init+0x1dc>
    800062a6:	c7fd                	beqz	a5,80006394 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800062a8:	6605                	lui	a2,0x1
    800062aa:	4581                	li	a1,0
    800062ac:	ffffb097          	auipc	ra,0xffffb
    800062b0:	a26080e7          	jalr	-1498(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800062b4:	0001c497          	auipc	s1,0x1c
    800062b8:	37c48493          	addi	s1,s1,892 # 80022630 <disk>
    800062bc:	6605                	lui	a2,0x1
    800062be:	4581                	li	a1,0
    800062c0:	6488                	ld	a0,8(s1)
    800062c2:	ffffb097          	auipc	ra,0xffffb
    800062c6:	a10080e7          	jalr	-1520(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800062ca:	6605                	lui	a2,0x1
    800062cc:	4581                	li	a1,0
    800062ce:	6888                	ld	a0,16(s1)
    800062d0:	ffffb097          	auipc	ra,0xffffb
    800062d4:	a02080e7          	jalr	-1534(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062d8:	100017b7          	lui	a5,0x10001
    800062dc:	4721                	li	a4,8
    800062de:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800062e0:	4098                	lw	a4,0(s1)
    800062e2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800062e6:	40d8                	lw	a4,4(s1)
    800062e8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800062ec:	6498                	ld	a4,8(s1)
    800062ee:	0007069b          	sext.w	a3,a4
    800062f2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800062f6:	9701                	srai	a4,a4,0x20
    800062f8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800062fc:	6898                	ld	a4,16(s1)
    800062fe:	0007069b          	sext.w	a3,a4
    80006302:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006306:	9701                	srai	a4,a4,0x20
    80006308:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000630c:	4705                	li	a4,1
    8000630e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006310:	00e48c23          	sb	a4,24(s1)
    80006314:	00e48ca3          	sb	a4,25(s1)
    80006318:	00e48d23          	sb	a4,26(s1)
    8000631c:	00e48da3          	sb	a4,27(s1)
    80006320:	00e48e23          	sb	a4,28(s1)
    80006324:	00e48ea3          	sb	a4,29(s1)
    80006328:	00e48f23          	sb	a4,30(s1)
    8000632c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006330:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006334:	0727a823          	sw	s2,112(a5)
}
    80006338:	60e2                	ld	ra,24(sp)
    8000633a:	6442                	ld	s0,16(sp)
    8000633c:	64a2                	ld	s1,8(sp)
    8000633e:	6902                	ld	s2,0(sp)
    80006340:	6105                	addi	sp,sp,32
    80006342:	8082                	ret
    panic("could not find virtio disk");
    80006344:	00002517          	auipc	a0,0x2
    80006348:	45450513          	addi	a0,a0,1108 # 80008798 <syscalls+0x338>
    8000634c:	ffffa097          	auipc	ra,0xffffa
    80006350:	1f2080e7          	jalr	498(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006354:	00002517          	auipc	a0,0x2
    80006358:	46450513          	addi	a0,a0,1124 # 800087b8 <syscalls+0x358>
    8000635c:	ffffa097          	auipc	ra,0xffffa
    80006360:	1e2080e7          	jalr	482(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006364:	00002517          	auipc	a0,0x2
    80006368:	47450513          	addi	a0,a0,1140 # 800087d8 <syscalls+0x378>
    8000636c:	ffffa097          	auipc	ra,0xffffa
    80006370:	1d2080e7          	jalr	466(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006374:	00002517          	auipc	a0,0x2
    80006378:	48450513          	addi	a0,a0,1156 # 800087f8 <syscalls+0x398>
    8000637c:	ffffa097          	auipc	ra,0xffffa
    80006380:	1c2080e7          	jalr	450(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006384:	00002517          	auipc	a0,0x2
    80006388:	49450513          	addi	a0,a0,1172 # 80008818 <syscalls+0x3b8>
    8000638c:	ffffa097          	auipc	ra,0xffffa
    80006390:	1b2080e7          	jalr	434(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006394:	00002517          	auipc	a0,0x2
    80006398:	4a450513          	addi	a0,a0,1188 # 80008838 <syscalls+0x3d8>
    8000639c:	ffffa097          	auipc	ra,0xffffa
    800063a0:	1a2080e7          	jalr	418(ra) # 8000053e <panic>

00000000800063a4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063a4:	7119                	addi	sp,sp,-128
    800063a6:	fc86                	sd	ra,120(sp)
    800063a8:	f8a2                	sd	s0,112(sp)
    800063aa:	f4a6                	sd	s1,104(sp)
    800063ac:	f0ca                	sd	s2,96(sp)
    800063ae:	ecce                	sd	s3,88(sp)
    800063b0:	e8d2                	sd	s4,80(sp)
    800063b2:	e4d6                	sd	s5,72(sp)
    800063b4:	e0da                	sd	s6,64(sp)
    800063b6:	fc5e                	sd	s7,56(sp)
    800063b8:	f862                	sd	s8,48(sp)
    800063ba:	f466                	sd	s9,40(sp)
    800063bc:	f06a                	sd	s10,32(sp)
    800063be:	ec6e                	sd	s11,24(sp)
    800063c0:	0100                	addi	s0,sp,128
    800063c2:	8aaa                	mv	s5,a0
    800063c4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063c6:	00c52d03          	lw	s10,12(a0)
    800063ca:	001d1d1b          	slliw	s10,s10,0x1
    800063ce:	1d02                	slli	s10,s10,0x20
    800063d0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800063d4:	0001c517          	auipc	a0,0x1c
    800063d8:	38450513          	addi	a0,a0,900 # 80022758 <disk+0x128>
    800063dc:	ffffa097          	auipc	ra,0xffffa
    800063e0:	7fa080e7          	jalr	2042(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800063e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063e6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800063e8:	0001cb97          	auipc	s7,0x1c
    800063ec:	248b8b93          	addi	s7,s7,584 # 80022630 <disk>
  for(int i = 0; i < 3; i++){
    800063f0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063f2:	0001cc97          	auipc	s9,0x1c
    800063f6:	366c8c93          	addi	s9,s9,870 # 80022758 <disk+0x128>
    800063fa:	a08d                	j	8000645c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800063fc:	00fb8733          	add	a4,s7,a5
    80006400:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006404:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006406:	0207c563          	bltz	a5,80006430 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000640a:	2905                	addiw	s2,s2,1
    8000640c:	0611                	addi	a2,a2,4
    8000640e:	05690c63          	beq	s2,s6,80006466 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006412:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006414:	0001c717          	auipc	a4,0x1c
    80006418:	21c70713          	addi	a4,a4,540 # 80022630 <disk>
    8000641c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000641e:	01874683          	lbu	a3,24(a4)
    80006422:	fee9                	bnez	a3,800063fc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006424:	2785                	addiw	a5,a5,1
    80006426:	0705                	addi	a4,a4,1
    80006428:	fe979be3          	bne	a5,s1,8000641e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000642c:	57fd                	li	a5,-1
    8000642e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006430:	01205d63          	blez	s2,8000644a <virtio_disk_rw+0xa6>
    80006434:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006436:	000a2503          	lw	a0,0(s4)
    8000643a:	00000097          	auipc	ra,0x0
    8000643e:	cfc080e7          	jalr	-772(ra) # 80006136 <free_desc>
      for(int j = 0; j < i; j++)
    80006442:	2d85                	addiw	s11,s11,1
    80006444:	0a11                	addi	s4,s4,4
    80006446:	ffb918e3          	bne	s2,s11,80006436 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000644a:	85e6                	mv	a1,s9
    8000644c:	0001c517          	auipc	a0,0x1c
    80006450:	1fc50513          	addi	a0,a0,508 # 80022648 <disk+0x18>
    80006454:	ffffc097          	auipc	ra,0xffffc
    80006458:	d2c080e7          	jalr	-724(ra) # 80002180 <sleep>
  for(int i = 0; i < 3; i++){
    8000645c:	f8040a13          	addi	s4,s0,-128
{
    80006460:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006462:	894e                	mv	s2,s3
    80006464:	b77d                	j	80006412 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006466:	f8042583          	lw	a1,-128(s0)
    8000646a:	00a58793          	addi	a5,a1,10
    8000646e:	0792                	slli	a5,a5,0x4

  if(write)
    80006470:	0001c617          	auipc	a2,0x1c
    80006474:	1c060613          	addi	a2,a2,448 # 80022630 <disk>
    80006478:	00f60733          	add	a4,a2,a5
    8000647c:	018036b3          	snez	a3,s8
    80006480:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006482:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006486:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000648a:	f6078693          	addi	a3,a5,-160
    8000648e:	6218                	ld	a4,0(a2)
    80006490:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006492:	00878513          	addi	a0,a5,8
    80006496:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006498:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000649a:	6208                	ld	a0,0(a2)
    8000649c:	96aa                	add	a3,a3,a0
    8000649e:	4741                	li	a4,16
    800064a0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064a2:	4705                	li	a4,1
    800064a4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800064a8:	f8442703          	lw	a4,-124(s0)
    800064ac:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064b0:	0712                	slli	a4,a4,0x4
    800064b2:	953a                	add	a0,a0,a4
    800064b4:	058a8693          	addi	a3,s5,88
    800064b8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800064ba:	6208                	ld	a0,0(a2)
    800064bc:	972a                	add	a4,a4,a0
    800064be:	40000693          	li	a3,1024
    800064c2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800064c4:	001c3c13          	seqz	s8,s8
    800064c8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064ca:	001c6c13          	ori	s8,s8,1
    800064ce:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800064d2:	f8842603          	lw	a2,-120(s0)
    800064d6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064da:	0001c697          	auipc	a3,0x1c
    800064de:	15668693          	addi	a3,a3,342 # 80022630 <disk>
    800064e2:	00258713          	addi	a4,a1,2
    800064e6:	0712                	slli	a4,a4,0x4
    800064e8:	9736                	add	a4,a4,a3
    800064ea:	587d                	li	a6,-1
    800064ec:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064f0:	0612                	slli	a2,a2,0x4
    800064f2:	9532                	add	a0,a0,a2
    800064f4:	f9078793          	addi	a5,a5,-112
    800064f8:	97b6                	add	a5,a5,a3
    800064fa:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800064fc:	629c                	ld	a5,0(a3)
    800064fe:	97b2                	add	a5,a5,a2
    80006500:	4605                	li	a2,1
    80006502:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006504:	4509                	li	a0,2
    80006506:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000650a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000650e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006512:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006516:	6698                	ld	a4,8(a3)
    80006518:	00275783          	lhu	a5,2(a4)
    8000651c:	8b9d                	andi	a5,a5,7
    8000651e:	0786                	slli	a5,a5,0x1
    80006520:	97ba                	add	a5,a5,a4
    80006522:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006526:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000652a:	6698                	ld	a4,8(a3)
    8000652c:	00275783          	lhu	a5,2(a4)
    80006530:	2785                	addiw	a5,a5,1
    80006532:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006536:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000653a:	100017b7          	lui	a5,0x10001
    8000653e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006542:	004aa783          	lw	a5,4(s5)
    80006546:	02c79163          	bne	a5,a2,80006568 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000654a:	0001c917          	auipc	s2,0x1c
    8000654e:	20e90913          	addi	s2,s2,526 # 80022758 <disk+0x128>
  while(b->disk == 1) {
    80006552:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006554:	85ca                	mv	a1,s2
    80006556:	8556                	mv	a0,s5
    80006558:	ffffc097          	auipc	ra,0xffffc
    8000655c:	c28080e7          	jalr	-984(ra) # 80002180 <sleep>
  while(b->disk == 1) {
    80006560:	004aa783          	lw	a5,4(s5)
    80006564:	fe9788e3          	beq	a5,s1,80006554 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006568:	f8042903          	lw	s2,-128(s0)
    8000656c:	00290793          	addi	a5,s2,2
    80006570:	00479713          	slli	a4,a5,0x4
    80006574:	0001c797          	auipc	a5,0x1c
    80006578:	0bc78793          	addi	a5,a5,188 # 80022630 <disk>
    8000657c:	97ba                	add	a5,a5,a4
    8000657e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006582:	0001c997          	auipc	s3,0x1c
    80006586:	0ae98993          	addi	s3,s3,174 # 80022630 <disk>
    8000658a:	00491713          	slli	a4,s2,0x4
    8000658e:	0009b783          	ld	a5,0(s3)
    80006592:	97ba                	add	a5,a5,a4
    80006594:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006598:	854a                	mv	a0,s2
    8000659a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000659e:	00000097          	auipc	ra,0x0
    800065a2:	b98080e7          	jalr	-1128(ra) # 80006136 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065a6:	8885                	andi	s1,s1,1
    800065a8:	f0ed                	bnez	s1,8000658a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065aa:	0001c517          	auipc	a0,0x1c
    800065ae:	1ae50513          	addi	a0,a0,430 # 80022758 <disk+0x128>
    800065b2:	ffffa097          	auipc	ra,0xffffa
    800065b6:	6d8080e7          	jalr	1752(ra) # 80000c8a <release>
}
    800065ba:	70e6                	ld	ra,120(sp)
    800065bc:	7446                	ld	s0,112(sp)
    800065be:	74a6                	ld	s1,104(sp)
    800065c0:	7906                	ld	s2,96(sp)
    800065c2:	69e6                	ld	s3,88(sp)
    800065c4:	6a46                	ld	s4,80(sp)
    800065c6:	6aa6                	ld	s5,72(sp)
    800065c8:	6b06                	ld	s6,64(sp)
    800065ca:	7be2                	ld	s7,56(sp)
    800065cc:	7c42                	ld	s8,48(sp)
    800065ce:	7ca2                	ld	s9,40(sp)
    800065d0:	7d02                	ld	s10,32(sp)
    800065d2:	6de2                	ld	s11,24(sp)
    800065d4:	6109                	addi	sp,sp,128
    800065d6:	8082                	ret

00000000800065d8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065d8:	1101                	addi	sp,sp,-32
    800065da:	ec06                	sd	ra,24(sp)
    800065dc:	e822                	sd	s0,16(sp)
    800065de:	e426                	sd	s1,8(sp)
    800065e0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065e2:	0001c497          	auipc	s1,0x1c
    800065e6:	04e48493          	addi	s1,s1,78 # 80022630 <disk>
    800065ea:	0001c517          	auipc	a0,0x1c
    800065ee:	16e50513          	addi	a0,a0,366 # 80022758 <disk+0x128>
    800065f2:	ffffa097          	auipc	ra,0xffffa
    800065f6:	5e4080e7          	jalr	1508(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065fa:	10001737          	lui	a4,0x10001
    800065fe:	533c                	lw	a5,96(a4)
    80006600:	8b8d                	andi	a5,a5,3
    80006602:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006604:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006608:	689c                	ld	a5,16(s1)
    8000660a:	0204d703          	lhu	a4,32(s1)
    8000660e:	0027d783          	lhu	a5,2(a5)
    80006612:	04f70863          	beq	a4,a5,80006662 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006616:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000661a:	6898                	ld	a4,16(s1)
    8000661c:	0204d783          	lhu	a5,32(s1)
    80006620:	8b9d                	andi	a5,a5,7
    80006622:	078e                	slli	a5,a5,0x3
    80006624:	97ba                	add	a5,a5,a4
    80006626:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006628:	00278713          	addi	a4,a5,2
    8000662c:	0712                	slli	a4,a4,0x4
    8000662e:	9726                	add	a4,a4,s1
    80006630:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006634:	e721                	bnez	a4,8000667c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006636:	0789                	addi	a5,a5,2
    80006638:	0792                	slli	a5,a5,0x4
    8000663a:	97a6                	add	a5,a5,s1
    8000663c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000663e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006642:	ffffc097          	auipc	ra,0xffffc
    80006646:	ba2080e7          	jalr	-1118(ra) # 800021e4 <wakeup>

    disk.used_idx += 1;
    8000664a:	0204d783          	lhu	a5,32(s1)
    8000664e:	2785                	addiw	a5,a5,1
    80006650:	17c2                	slli	a5,a5,0x30
    80006652:	93c1                	srli	a5,a5,0x30
    80006654:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006658:	6898                	ld	a4,16(s1)
    8000665a:	00275703          	lhu	a4,2(a4)
    8000665e:	faf71ce3          	bne	a4,a5,80006616 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006662:	0001c517          	auipc	a0,0x1c
    80006666:	0f650513          	addi	a0,a0,246 # 80022758 <disk+0x128>
    8000666a:	ffffa097          	auipc	ra,0xffffa
    8000666e:	620080e7          	jalr	1568(ra) # 80000c8a <release>
}
    80006672:	60e2                	ld	ra,24(sp)
    80006674:	6442                	ld	s0,16(sp)
    80006676:	64a2                	ld	s1,8(sp)
    80006678:	6105                	addi	sp,sp,32
    8000667a:	8082                	ret
      panic("virtio_disk_intr status");
    8000667c:	00002517          	auipc	a0,0x2
    80006680:	1d450513          	addi	a0,a0,468 # 80008850 <syscalls+0x3f0>
    80006684:	ffffa097          	auipc	ra,0xffffa
    80006688:	eba080e7          	jalr	-326(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
