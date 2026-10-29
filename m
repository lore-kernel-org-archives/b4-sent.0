From: Francesco Boccola <francesco.boccola@unina.it>
Date: Thu, 29 Oct 2026 16:30:46 +0100
Subject: [PATCH RFC] KVM: arm64: nVHE: Flush all TLBs when freeing a VM's
 stage-2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-nvhe-stage2-flush-v1-1-a87c7aaa91e1@unina.it>
X-B4-Tracking: v=1; b=H4sIAKVm42oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyNL3byyjFTd4pLE9FQj3bSc0uIMXcPUVItE4xSTVGNjQyWgvoKi1LT
 MCrCZ0UpBbs5KsRDB4tKkrNTkEpBpSrW1AEhTPUV6AAAA
X-Change-ID: 20261029-nvhe-stage2-flush-1ee8a3d4e331
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oupton@kernel.org>, 
 Fuad Tabba <fuad.tabba@linux.dev>, Joey Gouly <joey.gouly@arm.com>, 
 Steffen Eiden <seiden@linux.ibm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Mark Rutland <mark.rutland@arm.com>
Cc: linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-kernel@vger.kernel.org, 
 Francesco Boccola <francesco.boccola@unina.it>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793287846; l=12631;
 i=francesco.boccola@unina.it; s=20261029; h=from:subject:message-id;
 bh=UtI/YN5wADN8DnQ5jfEuOThcGftUiTaFauT7BPsh/+c=;
 b=xD7lyU3fZXM7phDidQjIcuDpjTj0ug9pOGdesW5XxmQsjm6gA4EZp5Tg4qPvz6Zw5Oh677DFk
 +NkzmlBsQEqAcePLdpBEeJyLW13tKrB0WeZkC91UHbl4TXk2ZxcbjBH
X-Developer-Key: i=francesco.boccola@unina.it; a=ed25519;
 pk=82q3OTrtEAajk43b58WBO5I1Hj8Gg8DU6k0GngJr9rA=
X-Endpoint-Received: by B4 Relay for francesco.boccola@unina.it/20261029 with auth_id=1353
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kvm_free_stage2_pgd() frees a VM's stage-2 page tables without invalidating
the TLBs. That is correct: the VM's VMID is not reused before the next VMID
rollover, and flush_context() then invalidates the entries of all VMIDs on
all CPUs (TLBI ALLE1IS).

In nVHE mode, however, a CPU that ran a guest makes the host's broadcast
TLB invalidations more expensive for the whole system until then, which
with 16-bit VMIDs usually means until the host reboots. With stress-ng
--tlb-shootdown on three CPUs of a cluster, the cyclictest maximum on a
fourth, isolated CPU goes, before and after one guest:
- Cortex-A53 (Zynq UltraScale+ KV260, no VHE, 6.1.70-rt): 53-72 us ->
  83-164 us;
- Cortex-A55 (RK3588, kvm-arm.mode=nvhe, kvmarm/next): 18-23 -> 78-97 us;
- Cortex-A76 (RK3588, kvm-arm.mode=nvhe, kvmarm/next): 16-30 -> 74-80 us.
It crosses clusters: after a guest on an A55, an isolated A76 goes from
14-18 us to 129-154 us. The same happens on kernel 6.12.113 (20-24 -> 44-49
us on the A55) and on 7.1.9 with and without PREEMPT_RT.

One guest that turns its stage-1 MMU on, even for a few microseconds, is
enough; a guest that keeps its MMU off is not. With VHE nothing changes.

The state is in the CPU that ran the guest: a local TLBI ALLE1 on that CPU
at teardown removes the effect on every CPU, the same on all the other CPUs
does not. Invalidating the dead VM's VMID (TLBI VMALLS12E1IS, as pKVM does
at teardown) does not remove it either, whether stage 2 is disabled while
it is issued (as __kvm_tlb_flush_vmid() does from the host's context) or
enabled; nor does invalidating VMID 0 or the host's stage 1 (A53).

So do the rollover's invalidation when the stage 2 of a VM that has run is
freed, in nVHE mode. That costs one TLB refill on every CPU per VM
teardown; 500 VMs created, run and torn down one after the other take 32.1
ms each with it and 33.4 ms without, and an isolated CPU meanwhile sees no
change in latency (15 us against 13 us).

Signed-off-by: Francesco Boccola <francesco.boccola@unina.it>
---
On Cortex-A53, A55 and A76 hosts in nVHE mode, a CPU that has run a guest
with its stage-1 MMU on makes the host's broadcast TLB invalidations more
expensive for the whole system until the next VMID rollover, which usually
means until the host reboots. The patch does the rollover's invalidation
(TLBI ALLE1IS) when the stage 2 of a VM that has run is freed; its commit
message has the measurements.

RFC because we can only describe what these cores do, not explain it. Which
per-CPU state survives the invalidation of the VM's VMID, and why it slows
the broadcast invalidations of other CPUs, is microarchitectural; an
explanation from someone who knows these TLBs would be welcome.
Questions:
- Is this known behaviour of these cores in nVHE mode (A53, A55 and A76
  here)?
- ALLE1IS also drops the host's own EL1&0 entries on every CPU. A local
  TLBI ALLE1 on the CPUs the VM ran on (mmu->last_vcpu_ran) is enough in
  our tests, but needs IPIs; would you prefer that?
- In protected mode, the host itself runs with stage 2, and the same test
  gives 112-153 us from boot, guest or not (18-23 us in nVHE mode before
  any guest). Is that expected?
- Should VHE hosts also invalidate (we see no effect there)?

Reproducer (below): tinyvm.c, a ~110-line KVM VMM running a guest (guest.S)
that turns its MMU on and powers off, and run.sh: stress-ng --tlb-shootdown
and cyclictest (SCHED_FIFO 99) on a freshly booted host, 3 x 20 s before
and after one such guest. Controls: a guest that keeps its MMU off (no
change), the same kernel in VHE mode (no change), this patch on kvmarm/next
(A55 19-22 -> 20-32 us, A76 14-24 -> 13-15 us).

To run it: make (or make CROSS_COMPILE=aarch64-linux-gnu- LDFLAGS=-static),
then, as root on a freshly booted host with stress-ng and cyclictest,
./run.sh -v <cyclictest CPU> -c <three other CPUs of its cluster> -g <guest
CPU>. The defaults (-v 3 -c 0-2 -g 2) fit a 4-CPU cluster; -m 0 runs the
control guest (MMU off). In our tests the cyclictest CPU was isolated
(isolcpus, nohz_full, rcu_nocbs).

Found while measuring containers run as KVM guests against plain containers
on these boards.

==> Makefile <==

CC = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
CFLAGS = -O2 -Wall

SPIN = 0
all: tinyvm guest-mmu0.bin guest-mmu1.bin

tinyvm: %: %.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

guest-mmu%.bin: guest.S
	$(CC) -nostdlib -static -Wl,-Ttext=0x40000000 -Wl,--build-id=none -DMMU=$* -DSPIN=$(SPIN) -o guest-mmu$*.elf $<
	$(OBJCOPY) -O binary guest-mmu$*.elf $@

clean:
	rm -f tinyvm guest-mmu*.elf guest-mmu*.bin

==> guest.S <==
/*
 * guest.S - the guest of tinyvm: with MMU=1 it turns its stage-1 MMU and
 * caches on (identity map of its RAM), writes a marker through the MMU, spins
 * for SPIN seconds (virtual counter) and powers the VM off (PSCI SYSTEM_OFF);
 * with MMU=0 it does the same with the MMU off.
 * Linked at the start of the guest RAM (0x40000000):
 *   gcc -nostdlib -static -Wl,-Ttext=0x40000000 -Wl,--build-id=none -DMMU=1 \
 *       -o guest-mmu.elf guest.S && objcopy -O binary guest-mmu.elf guest-mmu.bin
 */

	.text
	.globl	_start
_start:

	movz	x0, #0xff00		/* MAIR: attr0 Device-nGnRnE, attr1 Normal WB */
	msr	mair_el1, x0
	movz	x0, #0x3519		/* TCR: T0SZ 25, WBWA inner shareable walks, */
	movk	x0, #0x0080, lsl #16	/* 4 KB granule, no TTBR1 walks, */
	movk	x0, #0x0002, lsl #32	/* 40-bit PA */
	msr	tcr_el1, x0
	adr	x0, pgtable
	msr	ttbr0_el1, x0
	isb
	tlbi	vmalle1
	dsb	ish
	isb
	mrs	x0, sctlr_el1
	movz	x1, #0x1005		/* I, C, M */
	orr	x0, x0, x1
	msr	sctlr_el1, x0
	isb

	movz	x1, #(MARKER_ADDR >> 16), lsl #16
	movz	w2, #0x4d4d		/* "MM" */
	movk	w2, #(0x55 + MMU), lsl #16
	str	w2, [x1]
	dsb	sy

	mrs	x3, cntfrq_el0		/* spin SPIN seconds */
	mov	x4, #SPIN
	mul	x3, x3, x4
	mrs	x4, cntvct_el0
	add	x3, x3, x4
2:	mrs	x4, cntvct_el0
	cmp	x4, x3
	b.lo	2b

	movz	w0, #0x0008
	movk	w0, #0x8400, lsl #16	/* PSCI SYSTEM_OFF */
	hvc	#0
1:	wfi
	b	1b

	.balign	4096
pgtable:	/* level 1, 1 GB blocks: 0-1 GB Device, 1-2 GB Normal WB (the RAM) */
	.quad	0x0060000000000401
	.quad	0x0000000040000705
	.fill	510, 8, 0

==> tinyvm.c <==
/*
 * tinyvm <guest.bin> [cpu] - the smallest KVM VMM: one vCPU, 16 MB of RAM at
 * 0x40000000, no interrupt controller and no devices. It loads <guest.bin> at
 * the start of the RAM, runs the vCPU (pinned to [cpu]) until the guest powers
 * the VM off through PSCI, checks the marker the guest wrote and exits 0.
 * Build: gcc -O2 -o tinyvm tinyvm.c
 */

		     (offsetof(struct kvm_regs, x) / sizeof(uint32_t)))

static void die(const char *what)
{
	perror(what);
	exit(2);
}

int main(int argc, char **argv)
{
	struct kvm_userspace_memory_region region;
	struct kvm_vcpu_init init;
	struct kvm_one_reg reg;
	struct kvm_run *run;
	uint64_t pc = RAM_BASE;
	int kvm, vm, vcpu, fd, size;
	uint8_t *ram;
	struct stat st;
	uint32_t marker;

	if (argc < 2) {
		fprintf(stderr, "usage: %s <guest.bin> [cpu]\n", argv[0]);
		return 2;
	}
	alarm(120);	/* a guest that faults spins forever: give up */
	if (argc > 2) {
		cpu_set_t set;

		CPU_ZERO(&set);
		CPU_SET(atoi(argv[2]), &set);
		if (sched_setaffinity(0, sizeof(set), &set))
			die("sched_setaffinity");
	}
	kvm = open("/dev/kvm", O_RDWR | O_CLOEXEC);
	if (kvm < 0)
		die("/dev/kvm");
	vm = ioctl(kvm, KVM_CREATE_VM, 0);
	if (vm < 0)
		die("KVM_CREATE_VM");
	ram = mmap(NULL, RAM_SIZE, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
	if (ram == MAP_FAILED)
		die("mmap");
	fd = open(argv[1], O_RDONLY);
	if (fd < 0 || fstat(fd, &st) || st.st_size > (off_t)MARKER_OFF ||
	    read(fd, ram, st.st_size) != st.st_size)
		die(argv[1]);
	close(fd);
	region = (struct kvm_userspace_memory_region){
		.slot = 0, .guest_phys_addr = RAM_BASE, .memory_size = RAM_SIZE,
		.userspace_addr = (uintptr_t)ram,
	};
	if (ioctl(vm, KVM_SET_USER_MEMORY_REGION, &region))
		die("KVM_SET_USER_MEMORY_REGION");
	vcpu = ioctl(vm, KVM_CREATE_VCPU, 0);
	if (vcpu < 0)
		die("KVM_CREATE_VCPU");
	if (ioctl(vm, KVM_ARM_PREFERRED_TARGET, &init))
		die("KVM_ARM_PREFERRED_TARGET");
	init.features[0] |= 1 << KVM_ARM_VCPU_PSCI_0_2;
	if (ioctl(vcpu, KVM_ARM_VCPU_INIT, &init))
		die("KVM_ARM_VCPU_INIT");
	reg = (struct kvm_one_reg){ .id = CORE_REG(regs.pc), .addr = (uintptr_t)&pc };
	if (ioctl(vcpu, KVM_SET_ONE_REG, &reg))
		die("KVM_SET_ONE_REG pc");
	size = ioctl(kvm, KVM_GET_VCPU_MMAP_SIZE, 0);
	run = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, vcpu, 0);
	if (run == MAP_FAILED)
		die("mmap kvm_run");
	for (;;) {
		if (ioctl(vcpu, KVM_RUN, 0) && errno != EINTR)
			die("KVM_RUN");
		if (run->exit_reason == KVM_EXIT_SYSTEM_EVENT)
			break;
		fprintf(stderr, "unexpected exit %u\n", run->exit_reason);
		return 2;
	}
	memcpy(&marker, ram + MARKER_OFF, sizeof(marker));
	printf("guest done: system event %u, marker %#x (%s)\n", run->system_event.type, marker,
	       marker == 0x564d4d ? "MMU on" : marker == 0x554d4d ? "MMU off" : "BAD");
	close(vcpu);
	close(vm);
	close(kvm);
	return marker == 0x564d4d || marker == 0x554d4d ? 0 : 1;
}

==> run.sh <==

set -e
V=3 C=0-2 G=2 T=20 N=3 M=1
while getopts v:c:g:t:r:m: o; do
	case $o in
	v) V=$OPTARG ;; c) C=$OPTARG ;; g) G=$OPTARG ;; t) T=$OPTARG ;; r) N=$OPTARG ;;
	m) M=$OPTARG ;; *) exit 2 ;;
	esac
done
SNG=${STRESS_NG:-stress-ng}
CT=${CYCLICTEST:-cyclictest}
W=$(echo "$C" | awk -F, '{n = 0; for (i = 1; i <= NF; i++) { split($i, r, "-"); n += (r[2] == "" ? 1 : r[2] - r[1] + 1) } print n}')
part() { awk -v c="$1" '/^processor/ {p = $3} /^CPU part/ && p == c {print $4; exit}' /proc/cpuinfo; }
mode=$(dmesg 2>/dev/null | grep -o "kvm \[1\]: [A-Za-z ]*mode initialized" | sed 's/kvm \[1\]: //' | head -1)
echo "kernel $(uname -r) $(uname -v | grep -o PREEMPT_RT), ${mode:-KVM mode unknown (dmesg)}, up $(cut -d. -f1 /proc/uptime) s"
echo "cyclictest on CPU $V (part $(part $V)), stress-ng tlb-shootdown x$W on CPUs $C, guest on CPU $G (part $(part $G)), MMU=$M"
[ -r /sys/module/kvm/parameters/stage2_free_flush ] &&
	echo "stage2_free_flush $(cat /sys/module/kvm/parameters/stage2_free_flush)"

measure() { # <phase> <run>
	$SNG --tlb-shootdown "$W" --taskset "$C" -t $((T + 3)) --metrics-brief > sng.out 2>&1 &
	sp=$!
	sleep 1
	set -- "$1" "$2" $($CT -m -a "$V" -p 99 -i 1000 -l $((T * 1000)) -q 2>/dev/null |
		awk '/Avg:/ { for (i = 1; i < NF; i++) { if ($i == "Avg:") a = $(i + 1); if ($i == "Max:") m = $(i + 1) } } END { print a, m }')
	wait $sp
	ops=$(awk '/tlb-shootdown +[0-9]/ { print $(NF - 1) }' sng.out | tail -1)
	printf '%-6s %d  cyclictest avg %4s us  max %5s us   stress-ng %8s bogo-ops/s\n' "$1" "$2" "$3" "$4" "$ops"
	echo "$1 $3 $4 $ops" >> results.txt
}

rm -f results.txt
i=1; while [ $i -le $N ]; do measure before $i; i=$((i + 1)); done
./tinyvm guest-mmu$M.bin "$G"
i=1; while [ $i -le $N ]; do measure after $i; i=$((i + 1)); done
awk '{ a[$1] += $2; m[$1] += $3; o[$1] += $4; n[$1]++ }
END { printf "after/before (means): cyclictest avg x%.2f, max x%.2f; stress-ng throughput x%.2f\n",
	(a["after"] / n["after"]) / (a["before"] / n["before"]),
	(m["after"] / n["after"]) / (m["before"] / n["before"]),
	(o["after"] / n["after"]) / (o["before"] / n["before"]) }' results.txt
rm -f sng.out results.txt
---
 arch/arm64/kvm/mmu.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/arch/arm64/kvm/mmu.c b/arch/arm64/kvm/mmu.c
index a48f3f531..baeea69e7 100644
--- a/arch/arm64/kvm/mmu.c
+++ b/arch/arm64/kvm/mmu.c
@@ -1216,6 +1216,17 @@ void kvm_free_stage2_pgd(struct kvm_s2_mmu *mmu)
 	write_lock(&kvm->mmu_lock);
 	pgt = mmu->pgt;
 	if (pgt) {
+		/*
+		 * The VM's VMID is not reused before the next rollover, which
+		 * invalidates all VMIDs, so its TLB entries can stay until then.
+		 * In nVHE mode, however, a CPU that ran a guest with its stage-1
+		 * MMU on makes the host's broadcast TLB invalidations more
+		 * expensive for all CPUs, and invalidating the VM's VMID does not
+		 * stop it: do the rollover's invalidation now. A VM that never
+		 * ran has no VMID (0).
+		 */
+		if (!has_vhe() && atomic64_read(&mmu->vmid.id))
+			kvm_call_hyp(__kvm_flush_vm_context);
 		mmu->pgd_phys = 0;
 		mmu->pgt = NULL;
 		free_percpu(mmu->last_vcpu_ran);

---
base-commit: dd0bc00e3e9201fd49b62ff9cc07890c89003afe
change-id: 20261029-nvhe-stage2-flush-1ee8a3d4e331

Best regards,
--  
Francesco Boccola <francesco.boccola@unina.it>

