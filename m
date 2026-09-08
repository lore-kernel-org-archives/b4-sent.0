From: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
Subject: [PATCH 0/3] Update t40* tests to use modern style.
Date: Tue, 08 Sep 2026 15:44:52 -0400
Message-Id: <20260908-modernize-t4001-v1-0-cab3933a173f@fastmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBBA0avIrDUZJYKriEXVlJEoaREh7q5Yv
 sX/F3hyTB6q6AJHO3uebUASR6AHZXsS3AWDRJljiYWY5o6c5ZPEmiEmwrRZmqLUSpkSQrU4Mnx
 8x7r57bd2JL2+G7jvB240ABBzAAAA
X-Change-ID: 20260908-modernize-t4001-fb43302caaf9
To: git@vger.kernel.org
Cc: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=589;
 i=markchucarroll@fastmail.com; h=from:subject:message-id;
 bh=ob3lO711FvuEn45yWeybckH753ynETznTETSLtLx1nI=;
 b=owGbwMvMwCUWOPFJle/8tn2Mp9WSGLIWpO66OHmLU/+LwwXNpXPmGh89xLp7BV/ix+RzUckGB
 w0cqzcLdZSyMIhxMciKKbL8/yfQ+IrlgYRf0LtPMHNYmUCGMHBxCsBE/hQx/C+csGte6L6s4rUf
 4tw5PIxPat+6//Kc/JGTAme6j+6Ry77AyLA6xfzQHYuPU2vUJu+72zejufiBnKotj67jxWUPPlV
 GljMBAA==
X-Developer-Key: i=markchucarroll@fastmail.com; a=openpgp;
 fpr=FFFE1081EA04E0184E52EEF25191E47A4D9F86BE
X-Endpoint-Received: by B4 Relay for markchucarroll@fastmail.com/default with auth_id=1002
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Mark C. Chu-Carroll <markchucarroll@fastmail.com>
---
Mark C. Chu-Carroll (3):
      Update t4001 to use modern syntax.
      Update t4009 to use modern style.
      Update t4010 to use modern style.

 t/t4001-diff-rename.sh   | 31 +++++++++----------
 t/t4009-diff-rename-4.sh | 54 ++++++++++++++++-----------------
 t/t4010-diff-pathspec.sh | 78 ++++++++++++++++++++++++------------------------
 3 files changed, 82 insertions(+), 81 deletions(-)


---
base-commit: b8242b093d9e941a34460d715e3ce616a34ac3fe
change-id: 20260908-modernize-t4001-fb43302caaf9

