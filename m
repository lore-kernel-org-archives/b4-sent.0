From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Date: Mon, 09 Nov 2026 08:46:37 +0100
Subject: [PATCH 1/3] toaster: show projects and builds without build mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-toaster-projects-nobuild-v1-1-7e65cadc2d39@belden.com>
References: <20261109-toaster-projects-nobuild-v1-0-7e65cadc2d39@belden.com>
In-Reply-To: <20261109-toaster-projects-nobuild-v1-0-7e65cadc2d39@belden.com>
To: bitbake-devel@lists.openembedded.org
Cc: Patrick Vogelaar <patrick.vogelaar@belden.com>, 
 patrick.vogelaar.dev@mailbox.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794210409; l=10052;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=N65LSiKa9/3pwL3t/hdsKOjLnBULOjaNZ4lMNJTxhlQ=;
 b=SvAHDqVTt7dnsg7GomGx+m17qfsi74fXvPWC6eeICWSajwLqPJDUYfoZPfxS3XyfJ/Ys4KXjI
 klZjdVlAKK7CFL1jd1wuMWm/jDfDmbK/LVGR70UJwiceILfWSvk6ghO
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without build mode (TOASTER_BUILDSERVER unset, e.g. "toaster start
nobuild" or a server that only imports event logs), Toaster cannot run
builds, but it still groups builds into projects. Today the projects
are hard to reach in this mode: the "All projects" tab is hidden, and
a project link leads to its configuration page, which offers build and
configuration actions that cannot work.

Without build mode, treat every project like the default command line
builds project:

- always show the "All projects" tab
- link projects to their builds page
- hide the project top bar with its configuration tabs and build form
- redirect the project overview and main configuration page to builds
- hide the "New custom image" and "Edit custom image" build actions

Build mode is unchanged. Add tests/views/test_nobuild.py to cover the
project links, redirects and hidden actions in both modes.

AI-Generated: Uses Kiro (claude-opus-5.5)
Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
 lib/toaster/tests/views/test_nobuild.py            | 88 ++++++++++++++++++++++
 lib/toaster/toastergui/templates/base.html         |  2 -
 .../toastergui/templates/basebuildpage.html        |  3 +
 .../toastergui/templates/projecttopbar.html        |  2 +-
 .../toastergui/templatetags/project_url_tag.py     | 10 ++-
 lib/toaster/toastergui/views.py                    |  6 ++
 6 files changed, 105 insertions(+), 6 deletions(-)

diff --git a/lib/toaster/tests/views/test_nobuild.py b/lib/toaster/tests/views/test_nobuild.py
new file mode 100644
index 000000000..a8ee82179
--- /dev/null
+++ b/lib/toaster/tests/views/test_nobuild.py
@@ -0,0 +1,88 @@
+#! /usr/bin/env python3
+#
+# BitBake Toaster Implementation
+#
+# SPDX-License-Identifier: GPL-2.0-only
+#
+
+"""Project pages with and without build mode (TOASTER_BUILDSERVER)."""
+
+import os
+from unittest import mock
+
+from django.test import TestCase
+from django.urls import reverse
+from django.utils import timezone
+
+from orm.models import Project, Build, Variable, Layer, Layer_Version, Recipe
+
+
+class ProjectPagesBase(TestCase):
+
+    def setUp(self):
+        self.project = Project.objects.create(name="test project")
+        self.builds_url = reverse('projectbuilds', args=(self.project.id,))
+        self.config_url = reverse('project', args=(self.project.id,))
+
+        # a started build of an image recipe
+        now = timezone.now()
+        self.build = Build.objects.create(project=self.project, started_on=now,
+                                          completed_on=now,
+                                          outcome=Build.SUCCEEDED)
+        Variable.objects.create(build=self.build, variable_name='MACHINE',
+                                variable_value='qemux86-64')
+        layer_version = Layer_Version.objects.create(
+            build=self.build, layer=Layer.objects.create(name='meta-test'))
+        Recipe.objects.create(name='core-image-test', is_image=True,
+                              layer_version=layer_version)
+        self.build_url = reverse('builddashboard', args=(self.build.id,))
+
+    def projects_table_names(self):
+        response = self.client.get(reverse('all-projects'), {'format': 'json'})
+        self.assertEqual(response.status_code, 200)
+        return [row['name'] for row in response.json()['rows']]
+
+
+@mock.patch('toastergui.views.project_enable', True)
+@mock.patch.dict(os.environ, {'TOASTER_BUILDSERVER': '1'})
+class BuildModeTests(ProjectPagesBase):
+
+    def test_projects_table_links_to_configuration(self):
+        names = self.projects_table_names()
+        self.assertTrue(any(self.config_url + '"' in n for n in names), names)
+
+    def test_build_page_offers_new_custom_image(self):
+        response = self.client.get(self.build_url)
+        self.assertContains(response, 'id="menu-new-custom-image"')
+
+
+@mock.patch('toastergui.views.project_enable', False)
+@mock.patch.dict(os.environ, {'TOASTER_BUILDSERVER': '0'})
+class NoBuildModeTests(ProjectPagesBase):
+
+    def test_projects_tab_shown(self):
+        response = self.client.get(reverse('all-builds'))
+        self.assertContains(response, 'id="navbar-all-projects"')
+
+    def test_projects_table_links_to_builds(self):
+        names = self.projects_table_names()
+        self.assertTrue(any(self.builds_url + '"' in n for n in names), names)
+        self.assertFalse(any(self.config_url + '"' in n for n in names), names)
+
+    def test_configuration_pages_redirect_to_builds(self):
+        for url in (self.config_url,
+                    reverse('projectconf', args=(self.project.id,))):
+            response = self.client.get(url)
+            self.assertRedirects(response, self.builds_url,
+                                 fetch_redirect_response=False)
+
+    def test_builds_page_has_no_project_topbar(self):
+        response = self.client.get(self.builds_url)
+        self.assertEqual(response.status_code, 200)
+        self.assertNotContains(response, 'id="project-topbar"')
+
+    def test_build_page_has_no_custom_image_actions(self):
+        response = self.client.get(self.build_url)
+        self.assertContains(response, 'id="menu-download-build-log"')
+        self.assertNotContains(response, 'id="menu-new-custom-image"')
+        self.assertNotContains(response, 'id="menu-edit-custom-image"')
diff --git a/lib/toaster/toastergui/templates/base.html b/lib/toaster/toastergui/templates/base.html
index e90be6962..28af3a8ec 100644
--- a/lib/toaster/toastergui/templates/base.html
+++ b/lib/toaster/toastergui/templates/base.html
@@ -110,7 +110,6 @@
                 All builds
               </a>
               </li>
-              {% if project_enable %}
               <li id="navbar-all-projects"
               {% if request.resolver_match.url_name == 'all-projects'  %}
               class="active"
@@ -120,7 +119,6 @@
                 All projects
               </a>
               </li>
-              {% endif %}
             {% endif %}
               <li id="navbar-docs">
               <a target="_blank" href="http://docs.yoctoproject.org/toaster-manual/index.html#toaster-user-manual">
diff --git a/lib/toaster/toastergui/templates/basebuildpage.html b/lib/toaster/toastergui/templates/basebuildpage.html
index a41911f52..b7982dd2c 100644
--- a/lib/toaster/toastergui/templates/basebuildpage.html
+++ b/lib/toaster/toastergui/templates/basebuildpage.html
@@ -148,6 +148,8 @@
             </a>
           </li>
 
+          <!-- custom images can only be built in build mode -->
+          {% if project_enable %}
           {% with build.get_custom_image_recipes as custom_image_recipes %}
             {% if custom_image_recipes.count > 0 %}
               <!-- edit custom image built during this build -->
@@ -215,6 +217,7 @@
                 });
               </script>
             {% endif %}
+          {% endif %}
 
             <li  id="menu-delete-build">
             <a href="#delete-build-modal" id="delete-build" data-toggle="modal" data-target="#delete-build-modal" class="text-danger">
diff --git a/lib/toaster/toastergui/templates/projecttopbar.html b/lib/toaster/toastergui/templates/projecttopbar.html
index 768ca9455..5673f5c13 100644
--- a/lib/toaster/toastergui/templates/projecttopbar.html
+++ b/lib/toaster/toastergui/templates/projecttopbar.html
@@ -41,7 +41,7 @@
     </form>
   </div>
 
-  {% if not project.is_default %}
+  {% if project_enable and not project.is_default %}
   <div id="project-topbar">
     <ul class="nav nav-tabs">
       <li id="topbar-configuration-tab">
diff --git a/lib/toaster/toastergui/templatetags/project_url_tag.py b/lib/toaster/toastergui/templatetags/project_url_tag.py
index 7b6f15b2c..7554f2a28 100644
--- a/lib/toaster/toastergui/templatetags/project_url_tag.py
+++ b/lib/toaster/toastergui/templatetags/project_url_tag.py
@@ -2,6 +2,8 @@
 # SPDX-License-Identifier: GPL-2.0-only
 #
 
+import os
+
 from django import template
 from django.urls import reverse
 
@@ -10,8 +12,9 @@ register = template.Library()
 def project_url(parser, token):
     """
     Create a URL for a project's main page;
-    for non-default projects, this is the configuration page;
-    for the default project, this is the project builds page
+    for non-default projects in build mode, this is the configuration page;
+    for the default project, or without build mode, this is the project
+    builds page
     """
     try:
         tag_name, project = token.split_contents()
@@ -28,7 +31,8 @@ class ProjectUrlNode(template.Node):
     def render(self, context):
         try:
             project = self.project.resolve(context)
-            if project.is_default:
+            build_mode = os.environ.get('TOASTER_BUILDSERVER') == '1'
+            if project.is_default or not build_mode:
                 return reverse('projectbuilds', args=(project.id,))
             else:
                 return reverse('project', args=(project.id,))
diff --git a/lib/toaster/toastergui/views.py b/lib/toaster/toastergui/views.py
index 3192b7270..c43492af8 100644
--- a/lib/toaster/toastergui/views.py
+++ b/lib/toaster/toastergui/views.py
@@ -1522,6 +1522,10 @@ if True:
 
     # Shows the edit project page
     def project(request, pid):
+        # without build mode there is nothing to configure
+        if not project_enable:
+            return redirect('projectbuilds', pid=pid)
+
         project = Project.objects.get(pk=pid)
 
         if '1' == os.environ.get('TOASTER_PROJECTSPECIFIC'):
@@ -1815,6 +1819,8 @@ if True:
         return(vars_managed,sorted(vars_fstypes),vars_disallowed)
 
     def projectconf(request, pid):
+        if not project_enable:
+            return redirect('projectbuilds', pid=pid)
 
         try:
             prj = Project.objects.get(id = pid)

-- 
2.43.0

