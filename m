From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:21:52 -0800
Subject: [PATCH 02/36] xsm/flask: missing breaks, MISRA rule 16.4
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-2-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=1534;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=Om6cdnbe5fxG+CPjXPUOumzF0XPQ191PKf8s/8GFQ90=;
 b=w8ahloFDu924cxnDNLZ4R1wwM6DWcNf1t2DrnlPft9LzkIetQCU1BI/6U654/5ljvXy08gkyR
 0sUOpQD/agmCgTz6kCaQ8aW0762sTvVUZlawmKG9f0feuH2wHd5/HYB
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While working on console forwarding for virtual NS8250 I stepped into
  flask_domain_alloc_security()
where break statement was missing in default case which violates MISRA
rule 16.4.

Fixed everywhere in hooks.c.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/xsm/flask/hooks.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/xen/xsm/flask/hooks.c b/xen/xsm/flask/hooks.c
index dfa23738cd8a9fd91eda23d9c328c3cc55d31418..a79474ffe43af19f602a6c067eab6b40dba0d946 100644
--- a/xen/xsm/flask/hooks.c
+++ b/xen/xsm/flask/hooks.c
@@ -198,6 +198,7 @@ static int cf_check flask_domain_alloc_security(struct domain *d)
             else if ( pv_shim )
                 dsec->sid = SECINITSID_DOMU;
         }
+        break;
     }
 
     dsec->self_sid = dsec->sid;
@@ -342,6 +343,7 @@ static int cf_check flask_evtchn_send(struct domain *d, struct evtchn *chn)
         break;
     default:
         rc = avc_unknown_permission("event channel state", chn->state);
+        break;
     }
 
     return rc;
@@ -1310,6 +1312,7 @@ static int cf_check flask_hvm_param(struct domain *d, unsigned long op)
         break;
     default:
         perm = HVM__HVMCTL;
+        break;
     }
 
     return current_has_perm(d, SECCLASS_HVM, perm);
@@ -2013,6 +2016,7 @@ const struct xsm_ops *__init flask_init(
     case FLASK_BOOTPARAM_INVALID:
     default:
         panic("Flask: Invalid value for flask= boot parameter.\n");
+        break;
     }
 
     avc_init();

-- 
2.34.1

