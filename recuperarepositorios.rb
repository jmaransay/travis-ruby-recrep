require 'travis'
require 'travis/pro'
require 'time'
require 'travis/tools/github' 	# para acceder con el login de github, no lo usamos
require 'highline/import' 		# para ocultar contraseñas

# Recuperamos los argumentos al programa, el primero (cuasi) será el usuario cuyos repositorios comprobaremos

cuasi, rest = ARGV

# Incuimos nuestro token de Travis (ojo, es diferente del de GitHub)

Travis::Pro.access_token = 'YOURTRAVISCITOKEN'

# Organización en la que queremos hacer las comprobaciones

organization = 'POO1819'

# Array de pares [nombre práctica, fecha límite de entrega]:

repos_fechas = [
	['practica-01-02-parte-01', Time.utc(2018, 10, 19, 20, 00, 00)], ['practica-01-02-parte-02', Time.utc(2018, 10, 19, 20, 00, 00)], ['practica-01-02-parte-03', Time.utc(2018, 10, 19, 20, 00, 00)],
	['practica-01-03-parte-01', Time.utc(2018, 10, 19, 20, 00, 00)], ['practica-01-03-parte-02', Time.utc(2018, 10, 19, 20, 00, 00)],
	['practica-02-01-parte-01', Time.utc(2018, 11, 12, 20, 00, 00)], ['practica-02-01-parte-02', Time.utc(2018, 11, 12, 20, 00, 00)],
	['practica-02-02-parte-01', Time.utc(2018, 11, 12, 20, 00, 00)], ['practica-02-02-parte-02', Time.utc(2018, 11, 12, 20, 00, 00)],
]

# Acceso con credenciales GitHub, funciona también con autenticación en dos pasos

# Set up GitHub tool for doing the login handshake.
# github = Travis::Tools::Github.new(drop_token: true) do |g|
#  g.ask_login    = -> { ask("GitHub login: ") }
#  g.ask_password = -> { ask("Password: ") { |q| q.echo = "*" } }
#  g.ask_otp      = -> { ask("Two-factor token: ") }
# end

# Create temporary GitHub token and use it to authenticate against Travis CI.
# github.with_token do |token|
#  Travis::Pro.github_auth(token)
# end

# Mostramos el usuario con el que nos hemos logado

user = Travis::Pro::User.current
puts "Hola #{user.name}!"

# Mostramos las cuentas a las que tiene acceso (incluidas organizaciones)

Travis::Pro.accounts.each do |account|
  puts "La cuenta #{account.name} con login  #{account.login} y id #{account.id} tiene #{account.repos_count} repositorios"
end

# Parece que find_all está limitado a recuperar 25 repositorios, así que no parece la herramienta más adecuada para recuperar "todos los repositorios" de la organización:

# foo = Travis::Pro::Repository.find_all(owner_name: 'POO1819')
# puts "Repositorios recuperados: #{foo.count}"
# foo.each { |repository| puts "#{repository.slug} #{repository.last_build_state}" }

# Iteramos sobre el vector de prácticas y fechas límite:

repos_fechas.each do |repository| 
	
	# Generamos el nombre del repositorio con la organización, el nombre de la práctica y la cuenta del estudiante: 
	slug = organization + '/' + repository[0] + '-' + cuasi
	puts "\n"
	puts "COMPROBANDO repositorio: #{slug}"
	
	# cuidado, si find no encuentra nada, porque el estudiante no ha hecho la práctica, lanza una excepción; mirar el "raise" abajo.
	begin
		# Recupere
		rep =  Travis::Pro::Repository.find(slug)
		# puts "Repositorio #{rep.name}: "
		# Mostramos las características principales del último build:
		puts "Status de su último build:" 
		puts "- Número de builds: #{rep.last_build_number}" 
		puts "- Estado          : #{rep.last_build_state}" 
		puts "- Build start     : #{rep.last_build_started_at}"
		puts "- Build finished  : #{rep.last_build_finished_at}"
		puts "- Fecha commit    : #{rep.last_build.commit.committed_at}"
		puts "- Fecha entrega   : #{repository[1]}"
		puts "- Plazo cumplido  : #{rep.last_build.commit.committed_at < repository[1]}"
		# Algunos detalles adicionales que omitimos:
		# puts "- Autor           : #{rep.last_build.commit.author_name}"
   		# puts "- Commiter        : #{rep.last_build.commit.committer_name}"
 		# puts "- Commiter_email  : #{rep.last_build.commit.committer_name}"
   		# puts "- email           : #{rep.last_build.commit.author_email}"
		# puts "- rama            : #{rep.last_build.commit.branch}"
   		# puts "- asunto          : #{rep.last_build.commit.subject}"
		# puts "- mensaje         : #{rep.last_build.commit.message}"


		# build = rep.builds.detect { |b| b.failed? || b.errored? }
		
		# Buscamos un tag de nombre 'entrega' en el repositorio del estudiante, si existe, mostramos los valores de ese commit:

		build = rep.builds.detect { |b| b.branch_info == 'entrega' }
		if (build.nil?)
			puts "No hay un tag de nombre entrega"
		else
			puts "El estudiante ha generado un tag de nombre entrega:"
			puts "- Número de build : #{build.number}"
			puts "- Estado          : #{build.state}"
			puts "- Build start     : #{build.started_at}"
			puts "- Build finished  : #{build.finished_at}"
			puts "- Fecha Commit    : #{build.commit.committed_at}"
			puts "- Fecha entrega   : #{repository[1]}"
			puts "- Plazo cumplido  : #{build.commit.committed_at < repository[1]}"
			# Algunos detalles adicionales que omitimos:
			# puts "- Autor           : #{build.commit.author_name}"
   			# puts "- Commiter        : #{build.commit.committer_name}"
 			# puts "- Commiter_email  : #{build.commit.committer_name}"
   			# puts "- email           : #{build.commit.author_email}"
			# puts "- rama            : #{build.commit.branch}"
   			# puts "- asunto          : #{build.commit.subject}"
			# puts "- mensaje         : #{build.commit.message}"
		end
	rescue
		puts "Repositorio #{slug} no encontrado." 
	end
	puts "\n"
end
