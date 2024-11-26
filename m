From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:21:51 -0800
Subject: [PATCH 01/36] x86/setup: fix typo in acpi=off description
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-1-87b9a8375b7a@ford.com>
References: <20241126-vuart-ns8250-v1-v1-0-87b9a8375b7a@ford.com>
In-Reply-To: <20241126-vuart-ns8250-v1-v1-0-87b9a8375b7a@ford.com>
To: Jan Beulich <jbeulich@suse.com>, 
 Andrew Cooper <andrew.cooper3@citrix.com>, 
 =?utf-8?q?Roger_Pau_Monn=C3=A9?= <roger.pau@citrix.com>, 
 "Daniel P. Smith" <dpsmith@apertussolutions.com>, 
 Stefano Stabellini <sstabellini@kernel.org>, Julien Grall <julien@xen.org>, 
 Bertrand Marquis <bertrand.marquis@arm.com>, 
 Michal Orzel <michal.orzel@amd.com>, Rahul Singh <rahul.singh@arm.com>, 
 Volodymyr Babchuk <Volodymyr_Babchuk@epam.com>, 
 Alistair Francis <alistair.francis@wdc.com>, 
 Bob Eshleman <bobbyeshleman@gmail.com>, 
 Connor Davis <connojdavis@gmail.com>, 
 Oleksii Kurochko <oleksii.kurochko@gmail.com>, 
 Shawn Anastasio <sanastasio@raptorengineering.com>, 
 Anthony PERARD <anthony.perard@vates.tech>, Juergen Gross <jgross@suse.com>, 
 Christian Lindig <christian.lindig@citrix.com>, 
 David Scott <dave@recoil.org>, 
 =?utf-8?q?Marek_Marczykowski-G=C3=B3recki?= <marmarek@invisiblethingslab.com>
Cc: xen-devel@lists.xenproject.org, Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=913;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=7yTBjRl8lmc1tg+ZFlXhUwzuZwMkcPhVqwc9gw3xsIQ=;
 b=fGhLeTafOQHdmZPBdD9bIVheTVXsfAPHD70yBmhJl2mjqDLgSZD+W7NfTS1UpjOjg5WWyO82s
 3nLC9cTHbFbD0Zur6mUCtIfo/TkKIfkB94RsV1dDD42fBf/p2X0hkh9
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/x86/setup.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/xen/arch/x86/setup.c b/xen/arch/x86/setup.c
index d8661d7ca699c96f38229c75ad0a8626c6f675d4..0a748e2c14122d6c5d692bc5691e8cbe13a32c81 100644
--- a/xen/arch/x86/setup.c
+++ b/xen/arch/x86/setup.c
@@ -83,7 +83,7 @@ int8_t __initdata opt_probe_port_aliases = -1;
 boolean_param("probe-port-aliases", opt_probe_port_aliases);
 
 /* **** Linux config option: propagated to domain0. */
-/* "acpi=off":    Sisables both ACPI table parsing and interpreter. */
+/* "acpi=off":    Disables both ACPI table parsing and interpreter. */
 /* "acpi=force":  Override the disable blacklist.                   */
 /* "acpi=ht":     Limit ACPI just to boot-time to enable HT.        */
 /* "acpi=noirq":  Disables ACPI interrupt routing.                  */

-- 
2.34.1

