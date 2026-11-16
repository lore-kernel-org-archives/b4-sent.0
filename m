From: Hugo Sales <hugo@hsal.es>
Date: Mon, 16 Nov 2026 14:01:03 +0000
Subject: [PATCH v3 1/6] drm/amd/display: Render the panel power savings
 kernel-doc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-abm-sysfs-commit-v3-1-7a3d84a5328e@hsal.es>
References: <20261116-abm-sysfs-commit-v3-0-7a3d84a5328e@hsal.es>
In-Reply-To: <20261116-abm-sysfs-commit-v3-0-7a3d84a5328e@hsal.es>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: Mario Limonciello <mario.limonciello@amd.com>, Ray Wu <ray.wu@amd.com>, 
 Alex Hung <alex.hung@amd.com>, 
 Bhawanpreet Lakha <bhawanpreet.lakha@amd.com>, 
 Ivan Lipski <ivan.lipski@amd.com>, Chenyu Chen <chen-yu.chen@amd.com>, 
 David Weber <weber.aulendorf@gmail.com>, 
 Shivam Kalra <shivamkalra98@zohomail.in>, 
 Hamza Mahfooz <hamzamahfooz@linux.microsoft.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hugo Sales <hugo@hsal.es>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=972; i=hugo@hsal.es;
 h=from:subject:message-id; bh=FVHKsTcB+kzVbQ+9zevb2MG6df7WbrsHz6OXzX6yqvM=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsn7zzGdpqd6kKRUbEfRwLk8ZC0f8l2DxucdPWyQcL
 w3OtG69xNtRysIgxsUgK6bIonvDk4Fl4uSZOUXPl8DMYWUCGcLAxSkAE8lJZPgfkvfy3CKbJtZ3
 Dw0D5yWVVd+wNfn9997sl/vLWc45M98TZfif9GdGXfVTky+7z7+R/Ob15TTzVgXWg/E3JQ4FVAR
 d/tzKCQCkuUxx
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DOC section for the panel_power_savings sysfs file is not included
in any rst file, so it never shows up in the built documentation. Add it
to the Display Properties section next to the 'adaptive backlight
modulation' property it interacts with

Signed-off-by: Hugo Sales <hugo@hsal.es>
---
 Documentation/gpu/amdgpu/display/display-manager.rst | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/gpu/amdgpu/display/display-manager.rst b/Documentation/gpu/amdgpu/display/display-manager.rst
index f6de9e7779e29..ca4a956d2aa17 100644
--- a/Documentation/gpu/amdgpu/display/display-manager.rst
+++ b/Documentation/gpu/amdgpu/display/display-manager.rst
@@ -187,3 +187,6 @@ Display Properties
 
 .. kernel-doc:: drivers/gpu/drm/amd/amdgpu/amdgpu_display.c
    :doc: property for adaptive backlight modulation
+
+.. kernel-doc:: drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_backlight.c
+   :doc: panel power savings

-- 
2.56.0

