From: Nathan Lynch <nathanl@linux.ibm.com>
Subject: [PATCH 0/7] powerpc/pseries: new character devices for system
 parameters and VPD
Date: Fri, 06 Oct 2023 16:01:03 -0500
Message-Id: <20231006-papr-sys_rtas-vs-lockdown-v1-0-3a36bfb66e2e@linux.ibm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAI91IGUC/32NwQ6CMBAFf4X07JLSWhFP/ochBkqRjdCSLlYI4
 d+txLPHmeTNWxkZj4bYJVmZNwEJnY2QHRKmu8o+DGATmQkuJD9nOYzV6IEWuvupIggEvdPPxr0
 tKK2OiqumzgvB4n70psV5b9/KyB3S5PyyX4Xsa39VIf5UQwYcCilOQupW6ry+9mhfc4r1kGo3s
 HLbtg9QHc5xxgAAAA==
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>
Cc: linuxppc-dev@lists.ozlabs.org, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1696626070; l=3953;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=33bITNWtC+2JNViN32qS5UW9vQGmwDJdJ/Zwaw8wSzc=;
 b=DrHAnUGMQMwDIMPqbjwbppwVjDiWMF59RLXBox/f9t5HMgWP8l4UNZdn6cls4C4/DAfd1B/aF
 lR6rjKEyWjfAreyq1Ni+yU+ecq5iY318DYsvhESGHI3q0/OI0e5uaCL
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add character devices that expose PAPR-specific system parameters and
VPD to user space.

The problem: important platform features are enabled on Linux VMs
through the powerpc-specific rtas() syscall in combination with
writeable mappings of /dev/mem. In typical usage, this is encapsulated
behind APIs provided by the librtas library. This paradigm is
incompatible with lockdown, which prohibits /dev/mem access. It also
is too low-level in many cases: a single logical operation may require
multiple sys_rtas() calls in succession to complete. This carries the
risk that a process may exit while leaving an operation unfinished. It
also means that callers must coordinate their use of the syscall for
functions that cannot tolerate multiple concurrent clients, such as
ibm,get-vpd.

The solution presented here is to add a pair of small pseries-specific
"drivers," one for VPD and one for system parameters. The new drivers
expose these facilities to user space in ways that are compatible with
lockdown and require no coordination between their clients.

Both drivers could potentially support poll() methods to notify
clients of changes to parameters or VPD that happen due to partition
migration and other events. But that should be safe to leave for
later, assuming there's any interest.

I have made changes to librtas to prefer the new interfaces and
verified that existing clients work correctly with the new code. A
draft PR for that work is here:

https://github.com/ibm-power-utilities/librtas/pull/36

I expect to propose at least one more small driver in this style for
platform dump retrieval in a separate submission in the future. I
consider the work in this series mature enough now to request review
for inclusion as-is.

---
Changes in v1 vs initial RFC:
- Add papr-sysparm driver and tests.
- Add a papr-miscdev.h uapi header.
- Prevent sys_rtas() from interfering with papr-vpd call sequences.
- Handle -4 ("VPD changed") status in papr-vpd.
- Include string_helpers.h in papr-vpd.c, per Michal Suchánek
- Link to RFC: https://lore.kernel.org/r/20230822-papr-sys_rtas-vs-lockdown-v1-0-932623cf3c7b@linux.ibm.com

---
Nathan Lynch (7):
      powerpc/uapi: export papr-miscdev.h header
      powerpc/pseries: papr-vpd char driver for VPD retrieval
      powerpc/rtas: serialize ibm,get-vpd service with papr-vpd sequences
      powerpc/pseries/papr-sysparm: validate buffer object lengths
      powerpc/pseries/papr-sysparm: expose chardev API to user space
      powerpc/selftests: add test for papr-vpd
      powerpc/selftests: add test for papr-sysparm

 Documentation/userspace-api/ioctl/ioctl-number.rst |   4 +
 arch/powerpc/include/asm/papr-sysparm.h            |  17 +-
 arch/powerpc/include/asm/papr-vpd.h                |  18 +
 arch/powerpc/include/uapi/asm/papr-miscdev.h       |   9 +
 arch/powerpc/include/uapi/asm/papr-sysparm.h       |  58 +++
 arch/powerpc/include/uapi/asm/papr-vpd.h           |  22 +
 arch/powerpc/kernel/rtas.c                         |  26 +
 arch/powerpc/platforms/pseries/Makefile            |   1 +
 arch/powerpc/platforms/pseries/papr-sysparm.c      | 207 +++++++-
 arch/powerpc/platforms/pseries/papr-vpd.c          | 542 +++++++++++++++++++++
 tools/testing/selftests/powerpc/Makefile           |   2 +
 .../selftests/powerpc/papr_sysparm/.gitignore      |   1 +
 .../selftests/powerpc/papr_sysparm/Makefile        |  12 +
 .../selftests/powerpc/papr_sysparm/papr_sysparm.c  | 164 +++++++
 .../testing/selftests/powerpc/papr_vpd/.gitignore  |   1 +
 tools/testing/selftests/powerpc/papr_vpd/Makefile  |  12 +
 .../testing/selftests/powerpc/papr_vpd/papr_vpd.c  | 352 +++++++++++++
 17 files changed, 1440 insertions(+), 8 deletions(-)
---
base-commit: eddc90ea2af5933249ea1a78119f2c8ef8d07156
change-id: 20230817-papr-sys_rtas-vs-lockdown-5c54505db792

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

