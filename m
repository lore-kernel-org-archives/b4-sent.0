From: Levi Zim <rsworktech@outlook.com>
Date: Tue, 04 Feb 2025 10:00:21 +0800
Subject: [PATCH bpf-next] bpf: Add comment about helper freeze
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250204-bpf-helper-freeze-v1-1-46efd9ff20dc@outlook.com>
X-B4-Tracking: v=1; b=H4sIALR0oWcC/x2MwQqDMBAFf0X27EKMbaH+ingw9m1dKGnYiIjiv
 5v2ODAzB2WYIlNXHWRYNes3FmjqiqZ5jG+wvgqTd/7uvLtxSMIzPgnGYsAOnqSFC/4p4dFS6ZJ
 BdPs/e/rpEdtCw3lendXnF20AAAA=
X-Change-ID: 20250204-bpf-helper-freeze-cf3e0b29fb63
To: Andrii Nakryiko <andrii@kernel.org>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 Martin KaFai Lau <martin.lau@linux.dev>, 
 Eduard Zingerman <eddyz87@gmail.com>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, 
 John Fastabend <john.fastabend@gmail.com>, KP Singh <kpsingh@kernel.org>, 
 Stanislav Fomichev <sdf@fomichev.me>, Hao Luo <haoluo@google.com>, 
 Jiri Olsa <jolsa@kernel.org>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Levi Zim <rsworktech@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1621;
 i=rsworktech@outlook.com; s=k2025; h=from:subject:message-id;
 bh=6MxVW0yx3y2sc56aoIwnnQLxARMxNt5S7Q5kXG2Yyow=;
 b=owEBbQKS/ZANAwAIAW87mNQvxsnYAcsmYgBnoXS33Zgy50y0RZLE0DRtBqoIrdiBvqGAqn6se
 uVAuspSn+GJAjMEAAEIAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCZ6F0twAKCRBvO5jUL8bJ
 2KKwD/9EfjUuh1T541jPAYhMsPRyKAt2Hp/LKLLvN/+Ge4oP0zL7ZQUPyj/Rsu2vplfW0aLUUhx
 FQwikTq7LebKenRXqf8neZPlp0Rg+TytBV8WUd9fkH+pHeOekYBqmULHHn15OMueZPcOWNalpni
 bn+Zh4ZxegELJJKom3FhC49gtt6/seoYT41RPXw1xQrdmkcECZ5/lVAnUT82JAez6/TbL322Sqi
 IOsOWh8g+YnTYU2ThbnBkzqagxTeP3Q7P5GUpO15SlBZSk1iZaqYx5rllnoMXuDyIenDcwlWmRJ
 gUklsX3twS7OgzSksUuceaeoNVR17BRiQq60+l1RK3wyP3nfuhQgAGu/q2uNhtnBnoLsDJEyxMk
 O9qgD1F8YxRkkvxP84C0zbsAZb6L9F0k3OdyHZw5edYasp40dwzWsy/Pp0tFL6NiEWQSirb2Zu1
 jvTfWacUkEBgbjrbgnuB/OEGu42Hl2dXYewTZRas9dZVXxQK7JIi8maI2uw2iqyJGwZ0NeSw8lL
 HgYBDoq5W5mo9wt7sed+pe53qVoNaCxlpZRsn3WFY0EbKsuZPkydB8w95dYPY9pIKRzNgW7P4lm
 Eo2BGfZrV+9JAiGg1IoQcfiPESOOLAouSpO6G6/kL5IeGHZJF3yFiXmlMrvN/TJAdEg++kOE4Sv
 yfsbeYQg1Qzjnkw==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/k2025 with auth_id=336
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Put a comment after the bpf helper list in uapi bpf.h to prevent people
from trying to add new helpers there and direct them to kfuncs.

Link: https://lore.kernel.org/bpf/CAEf4BzZvQF+QQ=oip4vdz5A=9bd+OmN-CXk5YARYieaipK9s+A@mail.gmail.com/
Link: https://lore.kernel.org/bpf/20221231004213.h5fx3loccbs5hyzu@macbook-pro-6.dhcp.thefacebook.com/
Suggested-by: Andrii Nakryiko <andrii@kernel.org>
Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
Put a comment after the bpf helper list in uapi bpf.h to prevent people
from trying to add new helpers there and direct them to kfuncs.
---
 include/uapi/linux/bpf.h | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/include/uapi/linux/bpf.h b/include/uapi/linux/bpf.h
index 2acf9b33637174bd16b1d12ccc6410c5f55a7ea9..fff6cdb8d11a2c211a6205ae2937b2bdf593cd42 100644
--- a/include/uapi/linux/bpf.h
+++ b/include/uapi/linux/bpf.h
@@ -6019,7 +6019,10 @@ union bpf_attr {
 	FN(user_ringbuf_drain, 209, ##ctx)		\
 	FN(cgrp_storage_get, 210, ##ctx)		\
 	FN(cgrp_storage_delete, 211, ##ctx)		\
-	/* */
+	/* This helper list is effectively frozen. If you are trying to	\
+	 * add a new helper, you should add a kfunc instead which has	\
+	 * less stability guarantees. See Documentation/bpf/kfuncs.rst	\
+	 */
 
 /* backwards-compatibility macros for users of __BPF_FUNC_MAPPER that don't
  * know or care about integer value that is now passed as second argument

---
base-commit: 03f3aa4a6b664270d502c7fb44c634cbe250261e
change-id: 20250204-bpf-helper-freeze-cf3e0b29fb63

Best regards,
-- 
Levi Zim <rsworktech@outlook.com>

