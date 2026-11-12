From: Weidong Wang <weidongw@illinois.edu>
Date: Thu, 12 Nov 2026 00:56:11 -0600
Subject: [PATCH] ima: reject duplicate fsname= in a policy rule
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-c3-n204-v1-1-dd9400b9ece8@illinois.edu>
X-B4-Tracking: v=1; b=H4sIAAtj9WoC/yXMQQ5AMBCF4avIrDUxQ0pcRSyqBmNR0iIScXfF8
 kv+9y4I7IUD1MkFng8JsrgITBOwk3EjK+mjgTLSiEjK5spRVihTEWNZ6aIrNcR69TzI+T017e+
 wdzPb7Z3DfT+ayAPUawAAAA==
X-Change-ID: 20261112-c3-n204-a82e17864b76
To: Mimi Zohar <zohar@linux.ibm.com>, 
 Roberto Sassu <roberto.sassu@huawei.com>
Cc: Dmitry Kasatkin <dmitry.kasatkin@gmail.com>, 
 Eric Snowberg <eric.snowberg@oracle.com>, Paul Moore <paul@paul-moore.com>, 
 James Morris <jmorris@namei.org>, "Serge E. Hallyn" <serge@hallyn.com>, 
 linux-integrity@vger.kernel.org, linux-security-module@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Zijie Zhao <zijie4@illinois.edu>, 
 Weidong Wang <weidongw@illinois.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794466781; l=3130;
 i=weidongw@illinois.edu; s=20261108; h=from:subject:message-id;
 bh=YGNbmdIKoUZltwnBYfWkHQKsciAD4PKBCRhCaE1+1UI=;
 b=4mb0v9yD+DWL94QnJHXjVFAc9KVagxK9XVa02IFOvT8sgRKBXYR4REO5WY7iFuUHoGsCpmAz5
 hptdCWvDfCFCRSHcRMOFTmcIViSfxZYjR7/IMQjnieDszYjTMNYCxoR
X-Developer-Key: i=weidongw@illinois.edu; a=ed25519;
 pk=DR2S1xPEa5sELrWPfOpvUphJQ2VHC+MDc/wJavE/ifg=
X-Endpoint-Received: by B4 Relay for weidongw@illinois.edu/20261108 with auth_id=1449
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ima_parse_rule() stores the fsname= value with kstrdup() but, unlike
fsmagic=, fs_subtype= and the other options, does not check whether the
rule already has one. A rule that names fsname= twice overwrites
entry->fsname and leaks the first string.

Reject the duplicate with -EINVAL, as fs_subtype= does. Such a rule used
to be accepted with the last fsname= taking effect; giving the option
twice was never meaningful, and the other options already reject it.

Writing the policy requires CAP_SYS_ADMIN, so the leak is limited to a
few bytes per malformed rule loaded by a privileged user.

The leak was found by an AI code review agent (an LLM-based bug-finding
tool developed by Zijie Zhao and the submitter) and confirmed on an
unmodified kernel, without error injection, on x86_64 under QEMU with
kmemleak: loading 64 rules with a duplicated fsname= left 64
unreferenced objects allocated by kstrdup() in ima_parse_rule() (inlined
into ima_parse_add_rule()); the same rules with a single fsname= left
none. With this patch the duplicate rules are rejected and kmemleak
reports nothing; rules with a single fsname= are still accepted.

The reproducer, fix and changelog were drafted with AI assistance
(Claude), then reviewed and tested by the submitter.

Fixes: f1b08bbcbdaf ("ima: define a new policy condition based on the filesystem name")
Cc: Zijie Zhao <zijie4@illinois.edu>
Signed-off-by: Weidong Wang <weidongw@illinois.edu>
---
Tested on v7.4-rc1 (05441d697f7f), x86_64, QEMU/KVM, kmemleak, booted
with slab_debug=U. 64 rules written to the IMA policy file at once:

  trigger  "dont_measure fsname=pocfsA<i> fsname=pocfsB<i>"
  control  "dont_measure fsname=pocfsA<i>"

               trigger                         control
  unpatched    accepted; 64 unreferenced       accepted; none
               objects, all "pocfsA<i>"
  patched      write rejected; none            accepted; none

Without slab_debug=U kmemleak reports none of these leaks on this
kernel: stale pointers in the per-CPU slab sheaves keep the leaked
strings "referenced". Writing the policy more than once needs
CONFIG_IMA_WRITE_POLICY=y, which the test kernel has. The code is
unchanged in mainline, linux-next (next-20261111) and next-integrity.

The reproducer is available on request.
---
 security/integrity/ima/ima_policy.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/security/integrity/ima/ima_policy.c b/security/integrity/ima/ima_policy.c
index 2dc1d93aa..f08ca00bd 100644
--- a/security/integrity/ima/ima_policy.c
+++ b/security/integrity/ima/ima_policy.c
@@ -1619,6 +1619,11 @@ static int ima_parse_rule(char *rule, struct ima_rule_entry *entry)
 		case Opt_fsname:
 			ima_log_string(ab, "fsname", args[0].from);
 
+			if (entry->fsname) {
+				result = -EINVAL;
+				break;
+			}
+
 			entry->fsname = kstrdup(args[0].from, GFP_KERNEL);
 			if (!entry->fsname) {
 				result = -ENOMEM;

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261112-c3-n204-a82e17864b76

Best regards,
--  
Weidong Wang <weidongw@illinois.edu>

