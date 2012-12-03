if($("#epiceditor").length > 0) {
  var $editor = new EpicEditor({
      clientSideStorage: false,
      basePath: "/epiceditor",
      file: { defaultContent: $("#editor-content").attr("value") },
      theme: {
        base:'/themes/base/epiceditor.css',
        preview:'/themes/preview/github.css',
        editor:'/themes/editor/epic-light.css'
      },
  }).load();
}


$("#show-notes-list-button").on("click", function(e){
  e.preventDefault()
  $("#notes-list-button").toggle()
})

$("#note-editor").on("submit", function(e){
  $editor.preview()
  editor_value = $($editor.getElement('previewer')).find("#epiceditor-preview").html()
  $("#editor-content").attr("value", editor_value)
})
