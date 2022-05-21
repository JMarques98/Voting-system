pragma solidity ^0.8.10;

contract Administrado { //REQ4
    mapping(address => bool) administradores;
    
    modifier onlyAdmin() {
        require(administradores[msg.sender], "solo administrador");
        _;
    }
    
    constructor(address _administrador) public {
        administradores[_administrador] = true;
    }
 
    function addAdministrador(address _nuevoAdministrador) public onlyAdmin {
        administradores[_nuevoAdministrador] = true;
    }
}


contract Votacion is Administrado{ //REQ4
    
    struct Propuesta {
        string nombre;
        string detallePropuesta;
        uint idPropuesta;
        uint votos;
    }
    
    struct Votante {
        bool votado;
        uint8 pesoVoto;
        address delegarVotoTo;
        uint8 propuestaVotada;
    }
    
    enum EstadoVotacion {Preparacion, Abierta, Finalizada}

    EstadoVotacion public estado;
    uint public totalVotantes;
    uint public votosEfectuados;
    uint public propuestaGanadora;
    Propuesta[] internal propuestas;
    mapping(address => Votante) public vontantes;
    
    uint public fechaInicio; //Variable de fecha de inicio
    uint public fechaFin; //Variable que será la fehca fin
    uint public duracion = 2 minutes;//1 days; //La duración que querremos 
    
   
    modifier onlyEnPreparacion() {
       require(estado == EstadoVotacion.Preparacion,"votacion ya iniciada");
        _;
    }
    modifier onlyEnAbierta() {
         require(estado == EstadoVotacion.Abierta,"votacion finalizada");
        _;
    }
    
    constructor(address _administrador) Administrado(_administrador) public {
        estado = EstadoVotacion.Preparacion;
    }
    
    function addPropuesta(string memory nombreProp, string memory descPropuesta) public onlyAdmin onlyEnPreparacion {
     
        propuestas.push(Propuesta({nombre:nombreProp , detallePropuesta:descPropuesta,idPropuesta:propuestas.length+1 ,votos: 0 }));
    }
    
    function darDerechoDeVoto(address voterAddress) public onlyAdmin onlyEnPreparacion {
        require(vontantes[voterAddress].pesoVoto == 0, "Votante ya registrado");
        vontantes[voterAddress] = Votante({  votado: false, pesoVoto: 1,  delegarVotoTo : address(0), propuestaVotada : 0 });
        totalVotantes++;
     
    }
    
    function iniciarVotacion() public  onlyAdmin onlyEnPreparacion {
        estado = EstadoVotacion.Abierta;
        fechaInicio = block.timestamp;
        fechaFin = block.timestamp+duracion; //REQ1
    }
    
    function finalizarVotacion() public  onlyAdmin onlyEnAbierta {
        require(block.timestamp >= fechaFin, "Periodo votacion no finalizado");  //REQ1
        estado = EstadoVotacion.Finalizada;

       uint idPropuestaMasVotada = 0;
       uint votosPropuestaMasVotada = 0;
       
       for(uint i = 0; i < propuestas.length; i++) {
           if(propuestas[i].votos > votosPropuestaMasVotada) {
               idPropuestaMasVotada = i+1;
               votosPropuestaMasVotada = propuestas[i].votos ;
           }
       }
       
       propuestaGanadora = idPropuestaMasVotada;
    }
    
    //Funciones de los vontantes
    function votar(uint8 propuestaId) public onlyEnAbierta {
        Votante storage votanteEmisor = vontantes[msg.sender];
        require(votanteEmisor.votado == false, "ya ha votado");
        require(votanteEmisor.delegarVotoTo == address(0), "has  delegado");
        require(votanteEmisor.pesoVoto > 0, "no tienes derecho a voto");
        require(propuestaId >= 0 && propuestaId <= propuestas.length, "propuesta erronea");
        
        votanteEmisor.votado = true;
        votanteEmisor.propuestaVotada = propuestaId;
        if(propuestaId > 0) //REQ2
            propuestas[propuestaId-1].votos += votanteEmisor.pesoVoto ;
        
        votosEfectuados += votanteEmisor.pesoVoto;
    }
    
    function getPropuestabyId(uint8 propuestaId) public view returns(string memory nombreProp, string memory detallePropuesta) {
        nombreProp = propuestas[propuestaId-1].nombre;
        detallePropuesta  = propuestas[propuestaId-1].detallePropuesta;
    }
    
    function getPropuestaGanadora() public view returns(string memory nombreProp, string memory detallePropuesta) {
        nombreProp = propuestas[propuestaGanadora-1].nombre;
        detallePropuesta  = propuestas[propuestaGanadora-1].detallePropuesta;
    }
    
    function delegarVoto(address to) public  {
        require( estado != EstadoVotacion.Finalizada, "ya finalizada");
        require(to != msg.sender , "no puede delegar en el mismo");
        require(vontantes[to].pesoVoto > 0, "usuario no censado");
        
        Votante storage votanteEmisor = vontantes[msg.sender];
        require(!votanteEmisor.votado, "ya ha votado");
        require(votanteEmisor.delegarVotoTo == address(0), "ya ha delegado voto");
        
        while(vontantes[to].delegarVotoTo != address(0))  {
           to =  vontantes[to].delegarVotoTo;
           require(to != msg.sender,"bucle de delegacion");
        }
        
        votanteEmisor.delegarVotoTo = to;
        vontantes[to].pesoVoto += votanteEmisor.pesoVoto;
        
        if(vontantes[to].votado) {
            propuestas[vontantes[to].propuestaVotada-1].votos += votanteEmisor.pesoVoto;
        }
    }
}

contract VotacionesFactory is Administrado(msg.sender) {  //Req3
    
    address[] public votaciones;
    
    function nuevaVotacion() public onlyAdmin {
        votaciones.push(address(new Votacion(msg.sender) ));
    }
    
    function getTotalVotaciones() public view returns(uint) {
        return votaciones.length;
    }
}
