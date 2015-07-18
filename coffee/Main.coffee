'use strict'
class Renderer
  constructor: (qrdata, qrsize, options) ->
    @container = $('#WebGLContainer')
    width = @container.width()
    height = @container.height()
    @camera = new THREE.PerspectiveCamera 27, width / height, 1, 5000
    @camera.position.z = 600
    @controls = new THREE.OrbitControls @camera, @container[0]
    @controls.addEventListener 'change', => @render()
    @scene = new THREE.Scene()
    @ambientLight = new THREE.AmbientLight 0x888888
    @scene.add @ambientLight

    @directionalLight = new THREE.DirectionalLight 0x444444, 0.1
    @directionalLight.position.set 0, 0, 1
    @scene.add @directionalLight

    @cameraPointLight = new THREE.PointLight 0x888888, 0, 700
    @camera.add @cameraPointLight
    @scene.add @camera

    @pointLight = new THREE.PointLight 0x888888, 0, 700
    @pointLight.position.set 100, 100, 500
    @scene.add @pointLight

    @createBufferGeo(qrdata, qrsize, options)

    @meshPhongMaterial = new THREE.MeshPhongMaterial color: 0xdddddd, emissive: 0x000000, specular: 0x888888, shininess: 50, vertexColors: THREE.VertexColors
    @meshLambertMaterial = new THREE.MeshLambertMaterial color: 0xdddddd, emissive: 0x000000, vertexColors: THREE.VertexColors
    @meshBasicMaterial = new THREE.MeshBasicMaterial color: 0xdddddd, vertexColors: THREE.VertexColors
    @qrmaterial = @meshPhongMaterial
    @qrmesh = new THREE.Mesh @qrgeo, @qrmaterial
    @scene.add @qrmesh

    @renderer = new THREE.WebGLRenderer antialias: options.antialias
    @renderer.setClearColor new THREE.Color(options.backColor).getHex()
    @renderer.setPixelRatio window.devicePixelRatio
    @renderer.setSize width, height
    @renderer.gammaInput = true
    @renderer.gammaOutput = true

    @stats = Stats()
    @stats.domElement.style.position = 'absolute'
    @stats.domElement.style.top = '0px'
    @container.append @renderer.domElement
    @container.append @stats.domElement
    window.addEventListener 'resize', (e) => @onWindowResize(e)
    @controls.needsRender = true
    @animate()

  createBufferGeo: (qrdata, qrsize, options) ->
    @qrgeo = new THREE.BufferGeometry()
    positions = new Float32Array qrsize * qrsize * 12
    colors = new Float32Array qrsize * qrsize * 12
    normals = new Float32Array qrsize * qrsize * 12
    indices = new Uint32Array qrsize * qrsize * 6
    i = j = k = 0
    dark = new THREE.Color options.darkColor
    light = new THREE.Color options.lightColor
    for y in [0...qrsize] by 1
      for x in [0...qrsize] by 1
        positions[i     ] =  x    / qrsize *  200 - 100 # top left
        positions[i +  1] =  y    / qrsize * -200 + 100
        positions[i +  2] =  0
        positions[i +  3] = (x+1) / qrsize *  200 - 100 # top right
        positions[i +  4] =  y    / qrsize * -200 + 100
        positions[i +  5] =  0
        positions[i +  6] = (x+1) / qrsize *  200 - 100 # bottom right
        positions[i +  7] = (y+1) / qrsize * -200 + 100
        positions[i +  8] =  0
        positions[i +  9] =  x    / qrsize *  200 - 100 # bottom left
        positions[i + 10] = (y+1) / qrsize * -200 + 100
        positions[i + 11] =  0

        color = if qrdata[y][x] then dark else light
        colors[i    ] = colors[i + 3] = colors[i + 6] = colors[i +  9] = color.r
        colors[i + 1] = colors[i + 4] = colors[i + 7] = colors[i + 10] = color.g
        colors[i + 2] = colors[i + 5] = colors[i + 8] = colors[i + 11] = color.b

        normals[i    ] = normals[i + 3] = normals[i + 6] = normals[i +  9] = 0
        normals[i + 1] = normals[i + 4] = normals[i + 7] = normals[i + 10] = 0
        normals[i + 2] = normals[i + 5] = normals[i + 8] = normals[i + 11] = 1

        indices[j    ] = indices[j + 4] = k + 3
        indices[j + 1] = indices[j + 3] = k + 1
        indices[j + 2] = k
        indices[j + 5] = k + 2
        i += 12
        j += 6
        k += 4
    @qrgeo.addAttribute 'position', new THREE.BufferAttribute positions, 3
    @qrgeo.addAttribute 'color', new THREE.BufferAttribute colors, 3
    @qrgeo.addAttribute 'normal', new THREE.BufferAttribute normals, 3
    @qrgeo.addAttribute 'index', new THREE.BufferAttribute indices, 1
    @qrgeo.computeBoundingSphere()

  onWindowResize: ->
    width = @container.width()
    height = @container.height()
    @camera.aspect = width / height
    @camera.updateProjectionMatrix()
    @renderer.setSize width, height
    @render()

  animate: ->
    requestAnimationFrame => @animate()
    @controls.update()
    @stats.update()

  render: ->
    @renderer.render @scene, @camera

  exportPng: ->
    @renderer.render @scene, @camera
    window.open @renderer.domElement.toDataURL(), 'Exported png'

$('#qrModal').modal backdrop: 'static', keyboard: false

$('#generateQR').click ->
  ecl = switch $('#qrEcl').val()
    when '0' then QRErrorCorrectLevel.L
    when '1' then QRErrorCorrectLevel.M
    when '2' then QRErrorCorrectLevel.Q
    when '3' then QRErrorCorrectLevel.H
  qrcode = new QRCode parseInt($('#qrType').val()), ecl
  qrcode.addData $('#qrText').val()
  r = qrcode.make()
  if r == null
    options = {
      lightColor: $('#qrLightColor').val(),
      darkColor: $('#qrDarkColor').val(),
      backColor: $('#qrBackColor').val(),
      antialias: $('#qrAntialias').val() == '0'
    }
    window.qr3d = new Renderer qrcode.modules, qrcode.moduleCount, options
    $('#qrModal').modal 'hide'
    $('#editQrType').val($('#qrType').val())
    $('#editQrEcl').val($('#qrEcl').val())
    $('#editDarkColor').val($('#qrDarkColor').val())
    $('#editLightColor').val($('#qrLightColor').val())
    $('#editBackColor').val($('#qrBackColor').val())
    $('#editQrText').val($('#qrText').val())
  else
    alert "Error: Text is to long for selected type. The minimal type for the selected text is: #{r}"
    $('#qrType').val(r)

$('#exportPng').click -> window.qr3d.exportPng()

window.editMode = false
$('#showEdit, #closeEdit').click ->
  window.editMode = !window.editMode
  if window.editMode
    $('#showEdit').addClass('active')
    $('#showEdit').children('a').text('Hide edit scene configuration menu')
    $('#WebGLContainer').css('right','500px')
    qr3d.onWindowResize()
    $('#editMenu').show()
  else
    $('#showEdit').removeClass('active')
    $('#showEdit').children('a').text('Show edit scene configuration menu')
    $('#WebGLContainer').css('right','0px')
    qr3d.onWindowResize()
    $('#editMenu').hide()

# --------------------------------------- QR Code data ---------------------------------------

$('#changeQRcode').click ->
  ecl = switch $('#editQrEcl').val()
    when '0' then QRErrorCorrectLevel.L
    when '1' then QRErrorCorrectLevel.M
    when '2' then QRErrorCorrectLevel.Q
    when '3' then QRErrorCorrectLevel.H
  qrcode = new QRCode parseInt($('#editQrType').val()), ecl
  qrcode.addData $('#editQrText').val()
  r = qrcode.make()
  if r == null
    options = {
      lightColor: $('#editLightColor').val(),
      darkColor: $('#editDarkColor').val()
    }
    qr3d.createBufferGeo qrcode.modules, qrcode.moduleCount, options
    qr3d.scene.remove qr3d.qrmesh
    qr3d.qrmesh = new THREE.Mesh qr3d.qrgeo, qr3d.qrmaterial
    qr3d.scene.add qr3d.qrmesh
    qr3d.controls.needsRender = true
  else
    alert "Error: Text is to long for selected type. The minimal type for the selected text is: #{r}"
    $('#editQrType').val(r)

$('#editBackColor').change ->
  qr3d.renderer.setClearColor new THREE.Color($(@).val()).getHex()
  qr3d.controls.needsRender = true


# ----------------------------------------- Material -----------------------------------------

$('#editMaterial').val('0').change ->
  switch $(@).val()
    when '0' # MeshPhongMaterial
      qr3d.qrmaterial = qr3d.meshPhongMaterial
      qr3d.qrmaterial.emissive = new THREE.Color $('#editEmissiveColor').val()
      qr3d.qrmaterial.specular = new THREE.Color $('#editSpecularColor').val()
      qr3d.qrmaterial.shininess = parseFloat $('#editShininess').val()
      $('#editEmissiveColor').prop 'disabled', false
      $('#editSpecularColor').prop 'disabled', false
      $('#editShininess').prop 'disabled', false
    when '1' # MeshLambertMaterial
      qr3d.qrmaterial = qr3d.meshLambertMaterial
      qr3d.qrmaterial.emissive = new THREE.Color $('#editEmissiveColor').val()
      $('#editEmissiveColor').prop 'disabled', false
      $('#editSpecularColor').prop 'disabled', true
      $('#editShininess').prop 'disabled', true
    when '2' # MeshBasicMaterial
      qr3d.qrmaterial = qr3d.meshBasicMaterial
      $('#editEmissiveColor').prop 'disabled', true
      $('#editSpecularColor').prop 'disabled', true
      $('#editShininess').prop 'disabled', true
  qr3d.qrmaterial.color = new THREE.Color $('#editDiffuseColor').val()
  qr3d.qrmesh.material = qr3d.qrmaterial
  qr3d.controls.needsRender = true


$('#editDiffuseColor').val('#dddddd').change ->
  qr3d.qrmaterial.color = new THREE.Color $(@).val()
  qr3d.controls.needsRender = true

$('#editEmissiveColor').val('#000000').change ->
  qr3d.qrmaterial.emissive = new THREE.Color $(@).val()
  qr3d.controls.needsRender = true

$('#editSpecularColor').val('#888888').change ->
  qr3d.qrmaterial.specular = new THREE.Color $(@).val()
  qr3d.controls.needsRender = true

$('#editShininess').val(50).change ->
  qr3d.qrmaterial.shininess = parseFloat $(@).val()
  qr3d.controls.needsRender = true

# ------------------------------------------ Lights ------------------------------------------

$('#editAmbientLightColor').val('#888888').change ->
  qr3d.ambientLight.color = new THREE.Color $(@).val()
  qr3d.controls.needsRender = true

# Directional Light

$('#editEnableDirLight').prop('checked', true).change ->
  if $(@).prop('checked')
    qr3d.directionalLight.intensity = parseFloat $('#editDirLightIntensity').val()
  else
    qr3d.directionalLight.intensity = 0
  qr3d.controls.needsRender = true

$('#editDirLightColor').val('#444444').change ->
  qr3d.directionalLight.color = new THREE.Color $(@).val()
  qr3d.controls.needsRender = true

$('#editDirLightIntensity').val(0.1).change ->
  qr3d.directionalLight.intensity = parseFloat $(@).val()
  qr3d.controls.needsRender = true

$('#editDirLightX').val(0)
$('#editDirLightY').val(0)
$('#editDirLightZ').val(1)
$('#editDirLightVector').click ->
  x = parseFloat $('#editDirLightX').val()
  y = parseFloat $('#editDirLightY').val()
  z = parseFloat $('#editDirLightZ').val()
  qr3d.directionalLight.position.set(x, y, z).normalize()
  qr3d.controls.needsRender = true

# Camera Point Light

$('#editEnableCamLight').prop('checked', false).change ->
  if $(@).prop('checked')
    qr3d.cameraPointLight.intensity = parseFloat $('#editCameraLightIntensity').val()
  else
    qr3d.cameraPointLight.intensity = 0
  qr3d.controls.needsRender = true

$('#editCameraLightColor').val('#888888').change ->
  qr3d.cameraPointLight.color = new THREE.Color $(@).val()
  qr3d.controls.needsRender = true

$('#editCameraLightIntensity').val(0.7).change ->
  qr3d.cameraPointLight.intensity = parseFloat $(@).val()
  qr3d.controls.needsRender = true

$('#editCameraLightDistance').val(700).change ->
  qr3d.cameraPointLight.distance = parseFloat $(@).val()
  qr3d.controls.needsRender = true

# Static Point Light

$('#editEnablePointLight').prop('checked', false).change ->
  if $(@).prop('checked')
    qr3d.pointLight.intensity = parseFloat $('#editPointLightIntensity').val()
  else
    qr3d.pointLight.intensity = 0
  qr3d.controls.needsRender = true

$('#editPointLightColor').val('#888888').change ->
  qr3d.pointLight.color = new THREE.Color $(@).val()
  qr3d.controls.needsRender = true

$('#editPointLightIntensity').val(0.3).change ->
  qr3d.pointLight.intensity = parseFloat $(@).val()
  qr3d.controls.needsRender = true

$('#editPointLightDistance').val(700).change ->
  qr3d.pointLight.distance = parseFloat $(@).val()
  qr3d.controls.needsRender = true

$('#editPointLightX').val(100)
$('#editPointLightY').val(100)
$('#editPointLightZ').val(500)
$('#editPointLightPosition').click ->
  x = parseFloat $('#editPointLightX').val()
  y = parseFloat $('#editPointLightY').val()
  z = parseFloat $('#editPointLightZ').val()
  qr3d.pointLight.position.set(x, y, z)
  qr3d.controls.needsRender = true

# ----------------------------------------- Obstacle -----------------------------------------

obstacleMesh = null
$('#editObstacleWidth').val(50)
$('#editObstacleHeight').val(50)
$('#editObstacleColor').val('#FF0000')
$('#editObstacleX').val(30)
$('#editObstacleY').val(30)
$('#editObstacleZ').val(100)

$('#addObstacle').click ->
  if obstacleMesh?
    qr3d.scene.remove obstacleMesh
    qr3d.controls.needsRender = true
    obstacleMesh = null
    return $(@).text('Add obstacle')
  width = parseFloat $('#editObstacleWidth').val()
  height = parseFloat $('#editObstacleHeight').val()
  color = new THREE.Color($('#editObstacleColor').val()).getHex()
  x = parseFloat $('#editObstacleX').val()
  y = parseFloat $('#editObstacleY').val()
  z = parseFloat $('#editObstacleZ').val()
  obstacleGeo = new THREE.BufferGeometry()
  positions = new Float32Array 12
  normals = new Float32Array 12
  indices = new Uint32Array 6
  positions[ 0] = x - width  / 2 # top left
  positions[ 1] = y + height / 2
  positions[ 2] = z
  positions[ 3] = x + width  / 2 # top right
  positions[ 4] = y + height / 2
  positions[ 5] = z
  positions[ 6] = x + width  / 2 # bottom right
  positions[ 7] = y - height / 2
  positions[ 8] = z
  positions[ 9] = x - width  / 2 # bottom left
  positions[10] = y - height / 2
  positions[11] = z
  normals[0] = normals[3] = normals[6] = normals[9] = normals[1] = normals[4] = normals[7] = normals[10] = 0
  normals[2] = normals[5] = normals[8] = normals[11] = 1
  indices[0] = indices[4] = 3
  indices[1] = indices[3] = 1
  indices[2] = 0
  indices[5] = 2
  obstacleGeo.addAttribute 'position', new THREE.BufferAttribute positions, 3
  obstacleGeo.addAttribute 'normal', new THREE.BufferAttribute normals, 3
  obstacleGeo.addAttribute 'index', new THREE.BufferAttribute indices, 1
  obstacleGeo.computeBoundingSphere()
  obstacleMesh = new THREE.Mesh obstacleGeo, new THREE.MeshBasicMaterial color: color
  qr3d.scene.add obstacleMesh
  qr3d.controls.needsRender = true
  $(@).text('Remove obstacle')
