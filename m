From: Nathan Lynch <nathanl@linux.ibm.com>
Subject: [PATCH 0/2] powerpc/selftests: miscellaneous improvements
Date: Thu, 17 Aug 2023 11:21:51 -0500
Message-Id: <20230817-powerpc-selftest-misc-v1-0-a84cc1ef78b2@linux.ibm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAB9J3mQC/x3MywqDMBBG4VeRWTvgJFjFVxEXJf7aAS8hI21Bf
 HeDy29xzkmGpDDqipMSvmq6bxlSFhQ+720G65hNrnK+aqXhuP+QYmDDMh2wg1e1wOLCS6T28K6
 l3MaESf/Ptx+u6wZU2UJ7ZwAAAA==
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692289329; l=717;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=GfQHMVoWl2gmXXD4EiVWjePpkzCiMUIeoepITvP2O/o=;
 b=ioBzEPeDFokNnzBxp8fwEZpjvmrfYyX/OiLkqgG6cFDboxG3YcrWtViYTzzGBal9TfmnstUmn
 5fRke7ZM/oaAaWqk2q2ozOkvo9DUKn6GzY9O+Cl4PTQK+AEeZI4aKCW
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Just some minor things to tidy up I noticed when adding tests.

---
Nathan Lynch (2):
      powerpc/selftests: sort mm/.gitignore, add exec_prot
      selftests/powerpc: add const qualification where possible

 tools/testing/selftests/powerpc/harness.c         |  4 ++--
 tools/testing/selftests/powerpc/include/subunit.h | 16 ++++++++--------
 tools/testing/selftests/powerpc/include/utils.h   |  2 +-
 tools/testing/selftests/powerpc/mm/.gitignore     | 17 +++++++++--------
 4 files changed, 20 insertions(+), 19 deletions(-)
---
base-commit: 4f894fe22343138f0dc0ce18b49abfa45cdfeb6b
change-id: 20230817-powerpc-selftest-misc-12c61153e328

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

