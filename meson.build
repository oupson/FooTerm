project('footerm', ['c', 'vala'],
          version: '0.1.0',
    meson_version: '>= 0.59.0',
  default_options: [ 'warning_level=2', 'werror=false', ],
)

i18n = import('i18n')
gnome = import('gnome')

metadata_dir = meson.project_source_root() / 'bindings'/ 'metadata'
vapi_dir = meson.project_source_root() / 'bindings' / 'vapi'

add_project_arguments([
    # Make sure Meson can find custom VAPIs
    '--vapidir', vapi_dir,
    '--metadatadir', metadata_dir,
  ],
  language: 'vala'
)
add_project_arguments('-D_GNU_SOURCE', language: 'c')

subdir('data')
subdir('src')
subdir('po')

gnome.post_install(
     glib_compile_schemas: true,
    gtk_update_icon_cache: true,
  update_desktop_database: true,
)
