From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 04 Jan 2024 10:06:07 -0600
Subject: [PATCH] powerpc/pseries/lparcfg: drop error message from guest
 name lookup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240104-lparcfg-updates-v1-1-66a0184a4eb1@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIAG7XlmUC/x3MTQqAIBBA4avErBP8yYSuEi3ERhuIEq0IxLsnL
 b/FewUyJsIMU1cg4UOZzqNB9B24zR4BGa3NILlUQgrJ9miT84HdcbUXZoZe6EEZN2rDoVUxoaf
 3P85LrR9VyZygYQAAAA==
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 "Aneesh Kumar K.V" <aneesh.kumar@linux.ibm.com>, 
 "Naveen N. Rao" <naveen.n.rao@linux.ibm.com>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1704384374; l=1163;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=GMz0IiAh9zK5P880g/A7U6ApcCcqSeLA3Ql+a2XZK9Y=;
 b=O1xFqRDdGK5iRd8E3mmF8YTU9mQPmDWI4unbFo8rvxNIHwPuNzNIQJ+kvN0QEvz9QKmOdtkFB
 wgYIHj6T2l1DU/bmiamqFGCoamt6/CFJUFtQla9AD4xRuTvkiYtXVbp
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's not an error or exceptional situation when the hosting
environment does not expose a name for the LP/guest via RTAS or the
device tree. This happens with qemu when run without the '-name'
option. The message also lacks a newline. Remove it.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/platforms/pseries/lparcfg.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/powerpc/platforms/pseries/lparcfg.c b/arch/powerpc/platforms/pseries/lparcfg.c
index 1c151d77e74b..ff02ade17a75 100644
--- a/arch/powerpc/platforms/pseries/lparcfg.c
+++ b/arch/powerpc/platforms/pseries/lparcfg.c
@@ -357,8 +357,8 @@ static int read_dt_lpar_name(struct seq_file *m)
 
 static void read_lpar_name(struct seq_file *m)
 {
-	if (read_rtas_lpar_name(m) && read_dt_lpar_name(m))
-		pr_err_once("Error can't get the LPAR name");
+	if (read_rtas_lpar_name(m))
+		read_dt_lpar_name(m);
 }
 
 #define SPLPAR_MAXLENGTH 1026*(sizeof(char))

---
base-commit: 44a1aad2fe6c10bfe0589d8047057b10a4c18a19
change-id: 20231212-lparcfg-updates-ef15437c6570

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

