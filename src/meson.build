footerm_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
]

footerm_deps = [
  dependency('gtk4'),
  dependency('libadwaita-1'),
  dependency('vte-2.91-gtk4', version: '>= 0.70.0'),
]

footerm_sources += gnome.compile_resources('footerm-resources',
  'footerm.gresource.xml',
  c_name: 'footerm'
)

executable('footerm', footerm_sources,
  dependencies: footerm_deps,
       install: true,
)
