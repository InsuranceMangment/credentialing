// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 

contract Registration {
    

    address public regulatory_authority; 
    mapping(address => bool) public HealthcareFacility; 
    mapping(address => bool) public EvaluationCommitteMember; 
    mapping(address => bool) public Issuer; 

  
    //Modifiers
    
    modifier onlyregulatory_authority() {
        require(regulatory_authority == msg.sender, "Only the regulatory authority is eligible to run this function");
        _;
        
    }


    constructor() public {
        
        regulatory_authority = msg.sender;

    }
    
    
    function HealthcareFacilityRegistration (address user) public onlyregulatory_authority {
        require(HealthcareFacility[user] == false, "This facility is already registered");
        HealthcareFacility[user] = true;
        
    }
    
      function EvaluationCommitteMemberRegistration (address user) public onlyregulatory_authority {
        require(EvaluationCommitteMember[user] == false, "This member is already registered");
        EvaluationCommitteMember[user] = true;
    }
    
    function IssuerRegistration (address user) public onlyregulatory_authority{
        require(Issuer[user] == false, "This Issuer is already registered");
      Issuer[user] = true;
    }
    
}

contract DataValidation{

      struct ApplicationInfo{
          uint256  ApplicantID;
          ApplicationStatus  Applicationstatus; }

 Registration public reg_contract;
 string internal IPFShash;
 enum  PrimaryVerificationApprovalStatus {Not_Requested, Pending, Approved, Rejected}
 PrimaryVerificationApprovalStatus public PrimaryVerificationApprovalstatus;
 enum  ApplicationStatus {Not_Submitted,Pending, In_Progress, Approved, Rejected}
 ApplicationStatus  public Applicationstatus;
 uint256  ApplicantID;
 uint256   EndofDurationtime;  
 mapping(address => bool) public healthcareprofessional; 
 mapping(uint256 => address) public ApplicantApplicationNumberMapping;
 mapping( uint256 => ApplicationInfo) public ApplicationInfoMapping;
 mapping (address => bool) public IsApplcationIDSignedBy;
 mapping (address => bytes) public signatureOwner;
 mapping(uint256 => mapping (address => bool )) public isApplcationIDSignedBy;
  mapping (uint256 => mapping(address => bytes)) public ThesignatureOwner;
  mapping (uint256 => uint256) public PrimaryVerificationApproval; 


//mapping(application id => mapping(issuers => signature))
//mapping(application id => mapping(issuers => bool))
//mapping(application id => signaturecount)
 uint256 public ApplicationNumber; 
 uint256 public signaturesCount;
 uint256 NeededsignaturesNumbers;

 event newApplicationIsSubmitted (address healthcareprofessional, uint256 ApplicantID);
 event newPrimaryVerificationIsRequested (address HealthcareFacility, uint256 ApplicantID, uint256 Durationtime);
 event PrimaryVerificationisApproved(address HealthcareFacility, uint256 ApplicationNumber);
 event PrimaryVerificationisRejected(address HealthcareFacility, uint256 ApplicationNumber);
 event PrimaryVerificationTimeWindowisClosed (address HealthcareFacility, uint256 ApplicationNumber);
 event ApplicationisApproved(address EvaluationCommitteMember, uint256 ApplicationNumber);
 event ApplicationisRejected(address EvaluationCommitteMember, uint256 ApplicationNumber);
 event TheSignaturesuccessfullyStored (address issuers);  
 event TheSignatureFailedtobeStored (address issuers);      
    
  constructor (address RegistrationSCAddress) {
     reg_contract = Registration(RegistrationSCAddress);
  }

    modifier onlyRegisteredIssuer{
         require (reg_contract.Issuer(msg.sender), "only the Issuer is allowed to execute this function");
         _;
     }

      modifier onlyRegisteredEvaluationCommitteMember{
         require (reg_contract.EvaluationCommitteMember(msg.sender), "only a member from the Evaluation Committe is allowed to execute this function");
         _;
     }

      modifier onlyRegisteredHealthcareFacility{
         require (reg_contract.HealthcareFacility(msg.sender), "only a Healthcare Facility is allowed to execute this function");
         _;
     }
        modifier onlyRegisteredhealthcareprofessional {
         require (healthcareprofessional[msg.sender], "only a healthcare professional is allowed to execute this function");
         _;
     }

  

     function NewUserRegistration (address user) public {
        require(healthcareprofessional[user] == false, "This user is already registered");
       healthcareprofessional[user] = true; 
     }
    

     function NewApplication (string memory _IPFShash, uint256 _applicantID) public onlyRegisteredhealthcareprofessional{
        IPFShash =_IPFShash;
        ApplicantID = _applicantID;
        ApplicationNumber++;
        ApplicantApplicationNumberMapping[ApplicationNumber] = msg.sender; // link the application number to the applicant EA 
        ApplicationInfoMapping[ApplicationNumber] = ApplicationInfo (ApplicantID, Applicationstatus); // link the application number to the stuct application info 
        Applicationstatus=ApplicationStatus.Pending;
        PrimaryVerificationApprovalstatus=PrimaryVerificationApprovalStatus.Not_Requested;
        emit newApplicationIsSubmitted (msg.sender, ApplicantID);

     }
     function PrimaryVerificationRequest (uint256 _applicantID, uint256 _durationtime, uint256 _NeededsignaturesNumbers) public onlyRegisteredHealthcareFacility{
          require(_durationtime > 0, "The  Primary Verification Request duration time must be greater than zero");
          require(_NeededsignaturesNumbers > 0, "The number of  needed signatures must be greater than zero");
          require(PrimaryVerificationApprovalstatus == PrimaryVerificationApprovalStatus.Not_Requested, "Can't add a primary verification request as there is already a request for this new application");
          ApplicantID = _applicantID;
          EndofDurationtime = _durationtime; 
          NeededsignaturesNumbers =_NeededsignaturesNumbers;
          EndofDurationtime = block.timestamp + (_durationtime * 1 seconds);
          Applicationstatus=ApplicationStatus.In_Progress;
          PrimaryVerificationApprovalstatus=PrimaryVerificationApprovalStatus.Pending;
          emit newPrimaryVerificationIsRequested (msg.sender, ApplicantID, EndofDurationtime );

    }

    function storeSignatures(string memory message, bytes memory sig, uint256 _ApplicationNumber) public onlyRegisteredIssuer {
      require (isApplcationIDSignedBy[ApplicationNumber][msg.sender] == false, "This issuer is already signed");
      require (block.timestamp <  EndofDurationtime , "Primary Verification Time Window is Closed");
      require (signaturesCount < NeededsignaturesNumbers , "The number of needed signatures is already reached");
     require(isValidSignature(message,sig) == msg.sender, "Invalid signature"); 
     ThesignatureOwner[ApplicationNumber][msg.sender]= sig;
     isApplcationIDSignedBy[ApplicationNumber][msg.sender]= true;
     signaturesCount++;
     ApplicationNumber =_ApplicationNumber;
     PrimaryVerificationApproval [ApplicationNumber]= signaturesCount; 
     emit TheSignaturesuccessfullyStored (msg.sender);
     }
     //else if (block.timestamp <  EndofDurationtime && signaturesCount > NeededsignaturesNumbers)
      //{emit TheSignatureFailedtobeStored (msg.sender);
     // }

      //else if (block.timestamp > EndofDurationtime) {
 
     //emit PrimaryVerificationTimeWindowisClosed(msg.sender, ApplicationNumber);
     //} }
     
    

     function PrimaryVerificationApprovalResult ( uint256 _ApplicationNumber) public onlyRegisteredHealthcareFacility{
         ApplicationNumber =_ApplicationNumber;
     if(signaturesCount == NeededsignaturesNumbers){
                PrimaryVerificationApprovalstatus=PrimaryVerificationApprovalStatus.Approved;
                emit PrimaryVerificationisApproved(msg.sender, ApplicationNumber);
            } else {
                PrimaryVerificationApprovalstatus=PrimaryVerificationApprovalStatus.Rejected;
                emit PrimaryVerificationisRejected(msg.sender, ApplicationNumber);
            }
    }


    function Evaluation(uint256 _ApplicationNumber) public onlyRegisteredEvaluationCommitteMember{
        ApplicationNumber = _ApplicationNumber;
        require(signaturesCount == NeededsignaturesNumbers, "The number of received verifications is not enough");
        if (PrimaryVerificationApprovalstatus == PrimaryVerificationApprovalStatus.Approved) {
           Applicationstatus=ApplicationStatus.Approved;
           emit ApplicationisApproved(msg.sender, ApplicationNumber);
        }
        else if (PrimaryVerificationApprovalstatus==PrimaryVerificationApprovalStatus.Rejected) {
            Applicationstatus=ApplicationStatus.Rejected;
            emit ApplicationisRejected(msg.sender, ApplicationNumber);
        }

        
    } 
    


     function isValidSignature(string memory message, bytes memory sig) public pure returns (address signer) {

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := and(mload(add(sig, 65)), 255)
        }
        
        if (v < 27) v += 27;

        // The message header; we will fill in the length next
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
        // The first word of a string is its length
        length := mload(message)
        // The beginning of the base-10 message length in the prefix
        lengthOffset := add(header, 57)
        }
        // Maximum length we support
        require(length <= 999999);
        // The length of the message's length in base-10
        uint256 lengthLength = 0;
        // The divisor to get the next left-most message length digit
        uint256 divisor = 100000;
        // Move one digit of the message length to the right at a time
        while (divisor != 0) {
        // The place value at the divisor
        uint256 digit = length / divisor;
        if (digit == 0) {
            // Skip leading zeros
            if (lengthLength == 0) {
            divisor /= 10;
            continue;
            }
        }
        // Found a non-zero digit or non-leading zero digit
        lengthLength++;
        // Remove this digit from the message length's current value
        length -= digit * divisor;
        // Shift our base-10 divisor over
        divisor /= 10;
        
        // Convert the digit to its ASCII representation (man ascii)
        digit += 0x30;
        // Move to the next character and write the digit
        lengthOffset++;
        assembly {
            mstore8(lengthOffset, digit)
        }
        }
        // The null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
        lengthLength = 1 + 0x19 + 1;
        } else {
        lengthLength += 1 + 0x19;
        }
        // Truncate the tailing zeros from the header
        assembly {
        mstore(header, lengthLength)
        }
        // Perform the elliptic curve recover operation
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s); 
  
  

     
}
}
