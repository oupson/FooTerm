footerm_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
  'pane.vala',
  'newpane.vala',
  'newserver.vala',
  'terminalpane.vala',
]

footerm_deps = [
  dependency('gtk4'),
  dependency('libadwaita-1'),
  dependency('vte-2.91-gtk4', version: '>= 0.70.0'),
  dependency('json-glib-1.0', version: '>= 1.2.0'),
  dependency('libssh2'),
]

subdir('model')
subdir('services')

footerm_sources += gnome.compile_resources('footerm-resources',
  'footerm.gresource.xml',
  c_name: 'footerm'
)

executable('footerm', footerm_sources,
  dependencies: footerm_deps,
       install: true,
)
