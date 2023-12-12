From: Nathan Lynch <nathanl@linux.ibm.com>
Subject: [PATCH v6 00/13] powerpc/pseries: New character devices for system
 parameters and VPD
Date: Tue, 12 Dec 2023 11:01:47 -0600
Message-Id: <20231212-papr-sys_rtas-vs-lockdown-v6-0-e9eafd0c8c6c@linux.ibm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAPuReGUC/4XR3WrDMAwF4Fcpvp6LLUdO0qu9xxjDP8pq1ibB7
 ryWknefU8Y6tpBdHoE+HdCVJYqBEtttrixSDikMfQn6YcPc3vSvxIMvmYEAJRpZ89GMkadLeok
 nk3hO/DC4Nz989BwdVijQ27oFVvbHSF043+yn55L3IZ2GeLmdynKefqkAK2qWXPBWgQblOuVq+
 3gI/ft5G+xx64bjfGhWpBD6P0UZpW1ntSagX8rcL8N3JymkWtOgaGS8kI6ErAGWNPVDA1zTVNG
 QrKgQW6p9s6RVd02ufiFXRSsvqHzjbINisRveNRCrGhYNHLUatdIG/3SbpukT0NdXmkQCAAA=
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, 
 "Aneesh Kumar K.V (IBM)" <aneesh.kumar@kernel.org>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702400518; l=8289;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=28s4YaKXBXt8CxP/7m5F8OpG88IH8uhJk1wehKxssUM=;
 b=x2X0/PFdOgouy6n9mXkU8sGZuZXqCrMYJkuIdU3uJLII2yYTXjzNymQeuEIBzvzL0IWB0wr7Z
 VgkprtuJyciAxq4zKJlhCrEzBnqucff9JQJ5Z3qZrH+jckLRFawOk5U
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

These are the general problems, but it's difficult to formulate a
similarly general solution in the form of a single replacement ABI for
sys_rtas(). Instead, each platform facility we expose to user space
needs a specific interface that forms the kernel-user interactions at
a higher level than individual RTAS calls.

I've identified system parameter support as a high priority for this
effort, since the software that communicates with the management
console relies on it and therefore does not work at all with lockdown
enabled on current kernels. VPD retrieval is also important (for
licensing/entitlement things I think?), and serves as a good initial
example of encapsulating sequence-based RTAS calls. So this series
proposes a model for incrementally solving these issues by introducing
a small pseries-specific "driver" for each of these platform
functions. The new drivers expose these facilities to user space in
ways that are compatible with lockdown, and they require no
coordination between their clients.

In preparation, per-function mutexes are added to the core RTAS code
to serialize access to sequence-based RTAS functions. These prevent
kernel-based sequences from interfering with each other, and they
prevent sys_rtas() users from disrupting kernel-based users. The RTAS
core enforces correct lock usage when lockdep is enabled.

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
platform dump retrieval in a separate submission in the future. Other
facilities may follow as needs are identified.

---
Changes in v6:
- Require FMODE_WRITE for setting system parameters in papr-sysparm
  and add a corresponding testcase.
- Update existing sysparm testcases to open the device writable when
  attempting to set parameters.
- Link to v5: https://lore.kernel.org/r/20231207-papr-sys_rtas-vs-lockdown-v5-0-2ce965636a58@linux.ibm.com

Changes in v5:
- Add to the front of the queue another fix for a latent bug where
  sys_rtas() users can trigger a spurious warning backtrace.
- Merge "powerpc/uapi: Export papr-miscdev.h header" into "Add
  papr-vpd character driver for VPD retrieval" so we don't temporarily
  expose the PAPR_MISCDEV_IOC_ID constant via UAPI without also
  updating the ioctl-number documentation. (Michael Ellerman)
- Drop rtas_function_{un}lock() in favor of more explicit use of the new
  per-function mutexes; make rtas_ibm_get_vpd_lock extern for use by
  papr-vpd.
- Assert that rtas_ibm_get_vpd_lock is held in rtas_ibm_get_vpd().
- Add example usage to "powerpc/rtas: Facilitate high-level call
  sequences". (Aneesh Kumar K.V)
- Drop the now-unnecessary 04/13 "powerpc/rtas: Factor out function
  descriptor lookup".
- Include document version when citing the PAPR+ specification
  throughout. (Michael Ellerman)
- Add missing include directives to papr-vpd and papr-sysparm. (Michal
  Suchánek)
- Fix spurious testcase failure in environments without a working
  ibm,set-system-parameter RTAS function. (Michael Ellerman)
- Link to v4: https://lore.kernel.org/r/20231117-papr-sys_rtas-vs-lockdown-v4-0-b794d8cb8502@linux.ibm.com

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
      powerpc/rtas: Avoid warning on invalid token argument to sys_rtas()
      powerpc/rtas: Add for_each_rtas_function() iterator
      powerpc/rtas: Fall back to linear search on failed token->function lookup
      powerpc/rtas: Add function return status constants
      powerpc/rtas: Move token validation from block_rtas_call() to sys_rtas()
      powerpc/rtas: Facilitate high-level call sequences
      powerpc/rtas: Serialize firmware activation sequences
      powerpc/rtas: Warn if per-function lock isn't held
      powerpc/pseries: Add papr-vpd character driver for VPD retrieval
      powerpc/pseries/papr-sysparm: Validate buffer object lengths
      powerpc/pseries/papr-sysparm: Expose character device to user space
      powerpc/selftests: Add test for papr-vpd
      powerpc/selftests: Add test for papr-sysparm

 Documentation/userspace-api/ioctl/ioctl-number.rst |   4 +
 arch/powerpc/include/asm/papr-sysparm.h            |  17 +-
 arch/powerpc/include/asm/rtas.h                    |  28 +-
 arch/powerpc/include/uapi/asm/papr-miscdev.h       |   9 +
 arch/powerpc/include/uapi/asm/papr-sysparm.h       |  58 +++
 arch/powerpc/include/uapi/asm/papr-vpd.h           |  22 +
 arch/powerpc/kernel/rtas.c                         | 184 +++++--
 arch/powerpc/platforms/pseries/Makefile            |   1 +
 arch/powerpc/platforms/pseries/papr-sysparm.c      | 205 +++++++-
 arch/powerpc/platforms/pseries/papr-vpd.c          | 541 +++++++++++++++++++++
 tools/testing/selftests/powerpc/Makefile           |   2 +
 .../selftests/powerpc/papr_sysparm/.gitignore      |   1 +
 .../selftests/powerpc/papr_sysparm/Makefile        |  12 +
 .../selftests/powerpc/papr_sysparm/papr_sysparm.c  | 196 ++++++++
 .../testing/selftests/powerpc/papr_vpd/.gitignore  |   1 +
 tools/testing/selftests/powerpc/papr_vpd/Makefile  |  12 +
 .../testing/selftests/powerpc/papr_vpd/papr_vpd.c  | 352 ++++++++++++++
 17 files changed, 1596 insertions(+), 49 deletions(-)
---
base-commit: 27951e1d8274e9f9a2925b069e4492939a3f2099
change-id: 20230817-papr-sys_rtas-vs-lockdown-5c54505db792

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

