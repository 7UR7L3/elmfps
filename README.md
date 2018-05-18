elmfps
---

VIDEO DEMO: [https://vimeo.com/268923388](https://vimeo.com/268923388)
- Demo of networking encorporation with the main game.
- Rendering is somewhat disalligned with the networking but it is infinitely better than it was.
- Currently the server must be ran locally but could probably be coaxed onto the real person internet with Hamachi or port forwarding or something.

---

~~Our commit history was purged in a tragic accident because I don't know what "force push" and "unrecoverable" mean. This repository should still hold the up to date code. Our apologies. If there's a way to like get dat commit history back lemme know.~~ oh nvm ty git reflog <3

---

Now, you might ask yourself, why in the world would someone try to do something so stupid, and we ask ourselves that question every day.

If you're like lolwat, [this will probably be useful](https://htmlpreview.github.io/).
Namely, we'll try to keep a somewhat up to date .html _somewhere_ in the repo. Where? No idea. But it's there. Maybe.

As for what anything is, allow me to explain:
- [WebGL for Elm](http://package.elm-lang.org/packages/elm-community/webgl/latest) is actually pretty slick, and somehow (how is beyond us) appears to be quite performant. For now. Until we do something stupid and fuck it all up.
	- that link there is actually a great resource for figuring out what's what too.
- [Now this here](https://medium.com/@zenitram.oiram/a-beginners-guide-to-websockets-in-elm-and-crystal-8f510c28eb61) is (and fuck medium but whatever you get over it) something that could possibly be almost decent enough. How do we know? Well, we have no idea. It was just one of the first hits on google.
	- [The Kemal thing](http://kemalcr.com/) is probably the thing that we'll toss up on heroku and magic into something almost functional (ayy).
	- [And here's how](https://guide.elm-lang.org/architecture/effects/web_sockets.html) we get the socket things in the elm stuffs.
- [Keyboard Extra](https://github.com/ohanhi/keyboard-extra) is a thing that makes keyboard input fairly nice probably.

Trust us though, we have mad experience with this stuff.

This'll probably end having been quite inspired by ace of spades. It will also probably be rather cyan.

I apologize to our future selves.

---

---

### Project Updates for Spring 2018 Principles of Functional Programming Course taught by Matthew Hammer:

---

---

### Project Status Update: Multiplayer Shooter [4/3/18]
https://github.com/7UR7L3/elmfps

Demo: https://htmlpreview.github.io/?https://github.com/7UR7L3/elmfps/blob/master/fps.html

We have made fairly good progress on our project, though there is much we have yet to do.

We currently:
- Have a basic 3D renderer and some convenience methods for map making.
- Have keyboard input controls to move laterally.
- Have mouse pointer locking and rotation.
- Have basic networking / server (Elm Websockets / Node.js + Heroku) -- Eli is working in a separate branch on this and has yet to be incorporated into the main application.
 
We need to:
- Incorporate networking into the main application.
- Implement jumping / terrain collision.
- Add typical FPS things (health, ammo count, etc).
- Hit detection.
- Improve the shader for slightly better graphics.

---

---

### Project Proposal - Multiplayer Shooter [2/9/18]
 

#### Goals
Networked Multiplayer Shooter.

#### Plan of Attack
- Use webgl and kemal as server and elm websockets as client
- Make a basic 2D game where multiple people can connect
- Make a 3D world where multiple people can connect
- Implement movement, gravity, shooting, and collision (We aren't aiming for a full physics engine)
- Implement game rules

#### Algorithms and Data Structures
- Will likely use trees for objects of world, people, and projectiles 
- We'll likely use octrees(octonomial heaps ◕‿↼) for collision

---
#### For the next few weeks:
Eli will be working on
- networking
- basic message passing
- pondering what the best data structures will be for networking and what we will need

Michael will be working on
- getting a basic webgl renderer implemented in elm
- working on getting sufficient basic 3d graphics for a functional world
- figure out the best data structures for interaction and maps alongside algorithms that will be needed
