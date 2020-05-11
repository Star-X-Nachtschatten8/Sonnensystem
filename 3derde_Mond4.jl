    using FileIO
using LinearAlgebra
using GLMakie, AbstractPlotting
AbstractPlotting.__init__()

dt = 0.0001
N_Schritt = 50

dt = 60*60. / N_Schritt

AU = 149.6e9 # m
Masse_Erde = 5.972e24 # kg
Radius_Erde = 6378_000f0 # m

mutable struct Körper
    Position
    Geschinwigkeit
    Radius
    Masse
    Bild
    Object
    Attribute
end

function Körper(scene,   Position,   Geschinwigkeit,   Radius,  Masse,  Bild)
    Object = mesh!(scene,Sphere(Point3f0(0), Float32(Radius)), color = load(Bild), shading = false)[end]
    translate!(Object, Position);
    return Körper(Position,   Geschinwigkeit,   Radius,  Masse, Bild, Object, Dict())
end

position(K) = translation(K.Object)[]


scene = Scene(show_axis = false, center = false)

f_sun = 20*Radius_Erde
f = 1000 * Radius_Erde
#f = 200 * Radius_Erde

System = [Körper(scene,Point3f0(0,0,0), Point3f0(0,0,0), 109*f_sun, 1.989e30, "Sonne.jpg"),
          Körper(scene,Point3f0(0.387 * AU,0,0), Point3f0(0,47.4e3,0), 0.382 * f, 0.055 * Masse_Erde, "Merkur.png"),
          Körper(scene,Point3f0(0.723 * AU,0,0), Point3f0(0,35e3,0), 0.949 * f, 0.8150 * Masse_Erde, "Venus.jpg"),
          Körper(scene,Point3f0(AU,0,0), Point3f0(0,29.780e3,0), f, Masse_Erde, "Erde.png"),
          Körper(scene,Point3f0(1.524  * AU,0,0), Point3f0(0,24e3,0), 0.532 * f, 0.64171e24, "Mars.jpg"),
          Körper(scene,Point3f0(5.2 * AU,0,0), Point3f0(0,13.1e3,0), 11.19 * f, 1.898e27, "Jupiter.jpg"),
          Körper(scene,Point3f0(AU+405400e3,0,0), Point3f0(0,1.022e3 + 29.780e3 ,0), 0.2727 * f, 0.012 * Masse_Erde, "Mond.jpg")
          ]


#update_cam!(scene, Vec3f0(-10e10, 10e10, 10e10), Vec3f0(0))
update_cam!(scene, Vec3f0(0e10, 0e10, 10e10), Vec3f0(0), Vec3f0(0, 1, 0) )
scene.center = false # prevent to recenter on display

display(scene)

Zeit = Ref(0.)
Kräfte = zeros(length(System),3)
Positionen = zeros(length(System),3)
Geschwindigkeiten = zeros(length(System),3)
nPositionen = zeros(length(System),3)
nGeschwindigkeiten = zeros(length(System),3)

for i = 1:length(System)
    Geschwindigkeiten[i,:] = System[i].Geschinwigkeit;
end

function neuePosition(System,dt,Positionen,Geschwindigkeiten,Kräfte,nPositionen,nGeschwindigkeiten)
    G = 6.67430e-11 # m³/(kg s²)
    Kräfte .= 0

    for i = 1:length(System)
        for j = 1:length(System)
            if i ≠ j
                r = Positionen[i,:] - Positionen[j,:]
                Kraft = G * System[i].Masse * System[j].Masse * r ./ norm(r)^3
                Kräfte[i,:] = Kräfte[i,:] - Kraft
                Kräfte[j,:] = Kräfte[j,:] + Kraft
            end
        end
    end


    for i = 1:length(System)
        nGeschwindigkeiten[i,:] = Geschwindigkeiten[i,:] + Kräfte[i,:]/System[i].Masse * dt
        nPositionen[i,:] = Positionen[i,:] + Geschwindigkeiten[i,:] * dt
    end

end

function Zeitschritt(System,Zeit,Kräfte)


    for i = 1:length(System)
        Positionen[i,:] = translation(System[i].Object)[];
    end

    for n = 1:N_Schritt
        neuePosition(System,dt,Positionen,Geschwindigkeiten,Kräfte,nPositionen,nGeschwindigkeiten)
        @. nPositionen = (Positionen+nPositionen) * 0.5
        @. nGeschwindigkeiten = (Geschwindigkeiten+nGeschwindigkeiten) * 0.5
        neuePosition(System,dt,nPositionen,nGeschwindigkeiten,Kräfte,Positionen,Geschwindigkeiten)
    end

    for i = 1:length(System)
        t = translation(System[i].Object);
        t[] = Positionen[i,:]
    end

end

function anim(scene,System,Zeit,Kräfte)
    while isopen(scene)
        Zeit[] += 0.1

	    Zeitschritt(System,Zeit,Kräfte)
	    sleep(0.01)
    end
end


#task = @async anim(scene,System,Zeit,Kräfte)

anim(scene,System,Zeit,Kräfte)
stop() = schedule(task,InterruptException,error = true)

#=
close = false
while !close
global close
h = on(scene.events.window_open) do val
if !val
close = true
end
end
sleep(0.1)
end
=#

#Adrian
