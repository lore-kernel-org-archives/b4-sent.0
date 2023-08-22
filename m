From: Nathan Lynch <nathanl@linux.ibm.com>
Subject: [PATCH RFC 0/2] powerpc/pseries: new character devices for RTAS
 functions
Date: Tue, 22 Aug 2023 16:33:38 -0500
Message-Id: <20230822-papr-sys_rtas-vs-lockdown-v1-0-932623cf3c7b@linux.ibm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALIp5WQC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2MDC0Nz3YLEgiLd4sri+KKSxGLdsmLdnPzk7JT88jxd02RTE1MD05Qkc0s
 jJaD+gqLUtMwKsNnRSkFuzkqxtbUAE+q8h3AAAAA=
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>
Cc: linuxppc-dev@lists.ozlabs.org, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692740044; l=2907;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=z9fzCwu05p/kJat1VErjewoOFwejlqxL+Y9vVVA5YfE=;
 b=tbEDW3JN5f4jc5uhfkxn/pJjIwxbrWp0AnlI1Rn2WpSx8JKa/TFRAhPWQlr/3QzlYVb4lDWQ2
 7JLUF54mu9tABjKxRciHESjLtpbuk1GQB87ghoeTt3sTDqMbM6DSefl
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a proposal for adding chardev-based access to a select subset
of RTAS functions on the pseries platform.

The problem: important platform features are enabled on Linux VMs
through the powerpc-specific rtas() syscall in combination with
writeable mappings of /dev/mem. In typical usage, this is encapsulated
behind APIs provided by the librtas library. This paradigm is
incompatible with lockdown, which prohibits /dev/mem access.

The solution I'm working on is to add a small pseries-specific
"driver" for each functional area, exposing the relevant features to
user space in ways that are compatible with lockdown. In most of these
areas, I believe it's possible to change librtas to prefer the new
chardev interfaces without disrupting existing users.

I've broken down the affected functions into the following areas and
priorities:

High priority:
* VPD retrieval.
* System parameters: retrieval and update.

Medium priority:
* Platform dump retrieval.
* Light path diagnostics (get/set-dynamic-indicator,
  get-dynamic-sensor-state, get-indices).

Low priority (may never happen):
* Error injection: would have to be carefully restricted.
* Physical attestation: no known users.
* LPAR perftools: no known users.

Out of scope:
* DLPAR (configure-connector et al): involves device tree updates
  which must be handled entirely in-kernel for lockdown. This is the
  object of a separate effort.

See https://github.com/ibm-power-utilities/librtas/issues/29 for more
details.

In this RFC, I've included a single driver for VPD retrieval. Clients
use ioctl() to obtain a file descriptor-based handle for the VPD they
want. I think this could be a good model for the other areas too, but
I'd like to get opinions on it.

In the next iteration I expect to add a separate driver for system
parameters.

For reference, I floated a different approach for system parameters
here:

https://lore.kernel.org/linuxppc-dev/20220730000458.130938-1-nathanl@linux.ibm.com/

---
Nathan Lynch (2):
      powerpc/pseries: papr-vpd char driver for VPD retrieval
      powerpc/selftests: add test for papr-vpd

 Documentation/userspace-api/ioctl/ioctl-number.rst |   2 +
 arch/powerpc/include/uapi/asm/papr-vpd.h           |  29 ++
 arch/powerpc/platforms/pseries/Makefile            |   1 +
 arch/powerpc/platforms/pseries/papr-vpd.c          | 353 +++++++++++++++++++++
 tools/testing/selftests/powerpc/Makefile           |   1 +
 .../testing/selftests/powerpc/papr_vpd/.gitignore  |   1 +
 tools/testing/selftests/powerpc/papr_vpd/Makefile  |  12 +
 .../testing/selftests/powerpc/papr_vpd/papr_vpd.c  | 351 ++++++++++++++++++++
 8 files changed, 750 insertions(+)
---
base-commit: d77497508a229529830850ba07e1e52596463d21
change-id: 20230817-papr-sys_rtas-vs-lockdown-5c54505db792

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

