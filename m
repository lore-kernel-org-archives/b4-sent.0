From: Nathan Lynch <nathanl@linux.ibm.com>
Subject: [PATCH v4 00/13] powerpc/pseries: New character devices for system
 parameters and VPD
Date: Fri, 17 Nov 2023 23:14:18 -0600
Message-Id: <20231117-papr-sys_rtas-vs-lockdown-v4-0-b794d8cb8502@linux.ibm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACpIWGUC/4XO3UoDMRAF4FcpuTZlMtkkXa98DxHJz6wNtpslq
 bGl7LubLSJSZL08A/Odc2WFcqTCHjdXlqnGEtPYQvewYX5vxzfiMbTMEFDCThg+2Snzcimv+WQ
 Lr4Ufkn8P6XPkyqtOgQrO9Mja/5RpiOeb/fzS8j6WU8qXW1UVy/VbRVxRq+DAe4kapR+kN+7pE
 MeP8za649an41K0KAJA/6dIK7UbnNaEdKcs+yr+bBIg5JqGTSMbQHgCYRD/0uQvDdWaJpumyEG
 nVE8m7O61eZ6/APtvq6moAQAA
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700284468; l=5728;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=e9Ju/XtuI/yxX1VzJwg9mWUEi0MI6gctLUsH1iwDx2M=;
 b=VCywQHhiFuxsjY7N6KShZ/0xNr+OKPSrjC8USbblum5X1IaS1GnE3/prhC5QyweMcV7oEq/cy
 1m6mAJWtzT2DXAYI9zp2fY8ru9eOsnxe+oHnQ76BmrKm64O/5dO2zgt
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

Since the ibm,get-vpd call sequence performed by the papr-vpd driver
must be serialized against all other uses of the function, the series
begins by adding some new APIs to the core RTAS support code for this
purpose.

Both drivers could potentially support poll() methods to notify
clients of changes to parameters or VPD that happen due to partition
migration and other events. But that should be safe to leave for
later, assuming there's any interest.

I have made changes to librtas to prefer the new interfaces and
verified that existing clients work correctly with the new code. A
draft PR for that work is here:

https://github.com/ibm-power-utilities/librtas/pull/36

The user-space ABI has not changed since v1 of this series.

I expect to propose at least one more small driver in this style for
platform dump retrieval in a separate submission in the future.

---
Changes in v4:
- Fix latent issue in rtas_token_to_function() which causes boot-time
  crashes.
- More small preparatory changes: a function table iterator and
  additional symbolic constants for RTAS function return values.
- Use symbolic constants for ibm,get-vpd statuses in papr-vpd.c.
- Add commentary to papr_vpd_ioc_create_handle() explaining choice to
  retrieve all VPD at file handle creation time instead of deferring
  it to the read handler.
- Rebase on current powerpc/next.
- Link to v3: https://lore.kernel.org/r/20231025-papr-sys_rtas-vs-lockdown-v3-0-5eb04559e7d8@linux.ibm.com

Changes in v3:
- Add new rtas_function_lock()/unlock() APIs and convert existing code
  to use them.
- Convert papr-vpd to use rtas_function_lock()/unlock() instead of
  having sys_rtas() obtain a driver-private mutex.
- Rebase on current powerpc/next.
- Link to v2: https://lore.kernel.org/r/20231013-papr-sys_rtas-vs-lockdown-v2-0-ead01ce01722@linux.ibm.com

Changes in v2:
- Fix unused-but-set variable warning in papr-sysparm code.
- Rebase on powerpc/next branch.
- Link to v1: https://lore.kernel.org/r/20231006-papr-sys_rtas-vs-lockdown-v1-0-3a36bfb66e2e@linux.ibm.com

Changes in v1 vs initial RFC:
- Add papr-sysparm driver and tests.
- Add a papr-miscdev.h uapi header.
- Prevent sys_rtas() from interfering with papr-vpd call sequences.
- Handle -4 ("VPD changed") status in papr-vpd.
- Include string_helpers.h in papr-vpd.c, per Michal Suchánek
- Link to RFC: https://lore.kernel.org/r/20230822-papr-sys_rtas-vs-lockdown-v1-0-932623cf3c7b@linux.ibm.com

---
Nathan Lynch (13):
      powerpc/rtas: Add for_each_rtas_function() iterator
      powerpc/rtas: Fall back to linear search on failed token->function lookup
      powerpc/rtas: Add function return status constants
      powerpc/rtas: Factor out function descriptor lookup
      powerpc/rtas: Facilitate high-level call sequences
      powerpc/rtas: Serialize firmware activation sequences
      powerpc/rtas: Warn if per-function lock isn't held
      powerpc/uapi: Export papr-miscdev.h header
      powerpc/pseries: Add papr-vpd character driver for VPD retrieval
      powerpc/pseries/papr-sysparm: Validate buffer object lengths
      powerpc/pseries/papr-sysparm: Expose character device to user space
      powerpc/selftests: Add test for papr-vpd
      powerpc/selftests: Add test for papr-sysparm

 Documentation/userspace-api/ioctl/ioctl-number.rst |   4 +
 arch/powerpc/include/asm/papr-sysparm.h            |  17 +-
 arch/powerpc/include/asm/rtas.h                    |  27 +-
 arch/powerpc/include/uapi/asm/papr-miscdev.h       |   9 +
 arch/powerpc/include/uapi/asm/papr-sysparm.h       |  58 +++
 arch/powerpc/include/uapi/asm/papr-vpd.h           |  22 +
 arch/powerpc/kernel/rtas.c                         | 182 +++++--
 arch/powerpc/platforms/pseries/Makefile            |   1 +
 arch/powerpc/platforms/pseries/papr-sysparm.c      | 201 +++++++-
 arch/powerpc/platforms/pseries/papr-vpd.c          | 536 +++++++++++++++++++++
 tools/testing/selftests/powerpc/Makefile           |   2 +
 .../selftests/powerpc/papr_sysparm/.gitignore      |   1 +
 .../selftests/powerpc/papr_sysparm/Makefile        |  12 +
 .../selftests/powerpc/papr_sysparm/papr_sysparm.c  | 164 +++++++
 .../testing/selftests/powerpc/papr_vpd/.gitignore  |   1 +
 tools/testing/selftests/powerpc/papr_vpd/Makefile  |  12 +
 .../testing/selftests/powerpc/papr_vpd/papr_vpd.c  | 352 ++++++++++++++
 17 files changed, 1556 insertions(+), 45 deletions(-)
---
base-commit: 707df298cbde200b939c70be2577b20775fe3345
change-id: 20230817-papr-sys_rtas-vs-lockdown-5c54505db792

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

