From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Subject: [PATCH 0/3] Fix strlen() overwriting strtab's read-only data and
 zeros
Date: Sun, 18 Oct 2026 02:50:06 +0000
Message-Id: <20261018-bug010-strlen-strtab-v1-0-ac5f5bc6f8a0@d-matrix.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBCF4auUWRuYCZJKryJdNMm0jkgqmUSE0
 rub1tXjW7x/A+UsrDB0G2T+iMqaGujSQXhMaWEjsRksWkdIN+PrgoRGS35xOqZM3lC4sgt9tBE
 dtOs78yzfM3sf/9bqnxzK0YJ9/wHIYjdOeAAAAA==
X-Change-ID: 20261018-bug010-strlen-strtab-1c4e6c7d2d06
To: dtrace@lists.linux.dev
Cc: Kris Van Hees <kris.van.hees@oracle.com>, dtrace-devel@oss.oracle.com, 
 Eugene Loh <eugene.loh@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792291829; l=2518;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=fQyc5pENyzgoDhJthlgjKquBPGeCXlV4UZjUGNe3I40=;
 b=aN9Yzd2ZbevLICxK/ao8yatcEqMgNuGDDc5W+urx0MmILAw6vhBBD4DQRfR6wsOwNTm0ILNlF
 JTzMA0O7x+wDscEq40KkW/pFD+a4dD48mN7RHnm4Qyp+W1Q1QCfbpl4
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

strlen() copies its argument to the end of the string table in the
strtab map, which is where the block of zeros and the read-only data
have lived since commits d9d862b6 and e11098e2.  So strlen() of
anything longer than a few characters overwrites them for the rest of
the session:

  # dtrace -qn 'BEGIN { @[strlen("yyyyyyyyyyyyyyyyyyyyyyyyyyy")] =
                        count(); exit(0); }'

                 27 8753160913407277434

Patch 1 has the history and the other effects.  Patch 3 is hardening
and can be dropped: after patch 1 no BPF code writes to strtab, and
patch 3 has the verifier enforce that.

Giving strlen() its own space back is a one-line alternative:

-	dtp->dt_rooffset = P2ROUNDUP(dtp->dt_strlen, 8);
+	dtp->dt_rooffset = P2ROUNDUP(dtp->dt_strlen + strsize + 1, 8);

I chose the temporary string because it leaves strtab with no BPF
writer, which patch 3 relies on, and because with the one-liner all
CPUs write the same scratch bytes.  With 8 threads calling getppid()
under a clause doing four strlen() of 255 bytes, the one-liner ran at
3.2-3.7M calls/s and patch 1 at 5.4-5.6M (both 1.26M with one thread).
The cost is one more temporary string held during the call, as
strchr() does.  Happy to send a v2 with the one-liner if you prefer.

Tested on devel 61fea621, x86_64, Linux 6.8.  Over funcs/, aggs/,
assocs/, variables/, printa/, multiaggs/, arrays/, codegen/ and dif/
(778 tests), the only change from patches 1-2 and 1-3 is the two new
tests passing.  They also fail without patch 1 and pass with it on
dev-queue 0e93872f.

---
Eslam Almorshdy (3):
      Use a temporary string as scratch space for strlen()
      test: strlen() must not overwrite the rodata or the zeros
      Create the strtab map read-only for BPF programs

 bpf/strlen.c                                       |  4 +-
 libdtrace/dt_bpf.c                                 | 19 ++++++---
 libdtrace/dt_cg.c                                  | 13 +++++--
 test/unittest/funcs/strlen/tst.no-clobber-rodata.d | 37 ++++++++++++++++++
 test/unittest/funcs/strlen/tst.no-clobber-rodata.r |  3 ++
 test/unittest/funcs/strlen/tst.no-clobber-zeros.d  | 45 ++++++++++++++++++++++
 test/unittest/funcs/strlen/tst.no-clobber-zeros.r  |  5 +++
 7 files changed, 114 insertions(+), 12 deletions(-)
---
base-commit: 61fea621160ea4b6302874c62a723da105b44883
change-id: 20261018-bug010-strlen-strtab-1c4e6c7d2d06

Best regards,
--  
Eslam Almorshdy <ealmorshdy@d-matrix.ai>

